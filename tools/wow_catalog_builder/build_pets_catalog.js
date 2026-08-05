import axios from "axios";
import dotenv from "dotenv";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

dotenv.config({ quiet: true });

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");

const generatedDir = path.join(repoRoot, "assets/generated");
const petDataDir = path.join(repoRoot, "assets/data/pets");
const metadataPath = path.join(repoRoot, "assets/data/metadata/pets_metadata.json");
const locationsCatalogPath = path.join(
  generatedDir,
  "locations_reference_catalog.json",
);
const rawCatalogPath = path.join(generatedDir, "pets_catalog_raw.json");
const enrichedCatalogPath = path.join(generatedDir, "pets_catalog_enriched.json");
const wowheadExpansionIndexPath = path.join(
  generatedDir,
  "pets_wowhead_expansion_index.json",
);
const useOffline = process.argv.includes("--offline");

const expansions = [
  { wowheadId: 1, key: "vanilla", name: "Vanilla" },
  { wowheadId: 2, key: "tbc", name: "The Burning Crusade" },
  { wowheadId: 3, key: "wrath", name: "Wrath of the Lich King" },
  { wowheadId: 4, key: "cataclysm", name: "Cataclysm" },
  { wowheadId: 5, key: "mop", name: "Mists of Pandaria" },
  { wowheadId: 6, key: "wod", name: "Warlords of Draenor" },
  { wowheadId: 7, key: "legion", name: "Legion" },
  { wowheadId: 8, key: "bfa", name: "Battle for Azeroth" },
  { wowheadId: 9, key: "shadowlands", name: "Shadowlands" },
  { wowheadId: 10, key: "dragonflight", name: "Dragonflight" },
  { wowheadId: 11, key: "warWithin", name: "The War Within" },
  { wowheadId: 12, key: "midnight", name: "Midnight" },
];

const sourceMap = {
  ACHIEVEMENT: "Haut-fait",
  DISCOVERY: "Découverte",
  DROP: "Butin",
  PETSTORE: "Boutique",
  PROFESSION: "Métier",
  PROMOTION: "Promotion Blizzard",
  QUEST: "Quête",
  TCG: "Cartes à collectionner",
  TRADINGPOST: "Comptoir",
  VENDOR: "Vendeur",
  WILDPET: "Combat de mascottes",
  WORLDEVENT: "Événement mondial",
};

function firstNonEmpty(...values) {
  return values.find((value) => typeof value === "string" && value.trim()) ?? "";
}

function wowheadPetPageUrl(speciesId) {
  return `https://www.wowhead.com/fr/battle-pet/${speciesId}`;
}

async function getToken() {
  const params = new URLSearchParams();
  params.append("grant_type", "client_credentials");

  const response = await axios.post(
    "https://eu.battle.net/oauth/token",
    params,
    {
      auth: {
        username: process.env.BATTLENET_CLIENT_ID,
        password: process.env.BATTLENET_CLIENT_SECRET,
      },
    },
  );

  return response.data.access_token;
}

async function fetchBlizzardJson(url, token, params = {}) {
  const response = await axios.get(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    params: {
      namespace: "static-eu",
      locale: "fr_FR",
      ...params,
    },
  });

  return response.data;
}

async function delay(milliseconds) {
  await new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function loadExistingEnrichedPets() {
  try {
    const content = await fs.readFile(enrichedCatalogPath, "utf8");
    const data = JSON.parse(content);

    return new Map(data.map((pet) => [pet.id, pet]));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
    return new Map();
  }
}

async function loadJson(filePath, fallback) {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") return fallback;
    throw error;
  }
}

async function fetchPetDetails(pets, token, existingById) {
  const enrichedPets = [];
  const failedIds = [];
  const concurrency = 3;
  let nextIndex = 0;

  async function fetchWithRetry(pet) {
    const retries = 4;

    for (let attempt = 0; attempt <= retries; attempt += 1) {
      try {
        return await fetchBlizzardJson(
          `https://eu.api.blizzard.com/data/wow/pet/${pet.id}`,
          token,
        );
      } catch (error) {
        const status = error?.response?.status;

        if (status !== 429 || attempt === retries) {
          throw error;
        }

        await delay(750 * (attempt + 1));
      }
    }
  }

  async function worker() {
    while (nextIndex < pets.length) {
      const index = nextIndex;
      nextIndex += 1;
      const pet = pets[index];
      const cached = existingById.get(pet.id);

      if (cached?.sourceType || cached?.description) {
        enrichedPets.push(cached);
        continue;
      }

      try {
        await delay(120);
        const details = await fetchWithRetry(pet);

        enrichedPets.push({
          id: details.id,
          name: details.name,
          description: details.description ?? "",
          sourceType: details.source?.type ?? "",
          sourceName: details.source?.name ?? "",
          creatureId: details.creature?.id ?? null,
          creatureName: details.creature?.name ?? "",
          isCapturable: details.is_capturable ?? false,
          isTradable: details.is_tradable ?? false,
        });
      } catch (error) {
        failedIds.push(pet.id);
        console.log(`ERREUR PET ID ${pet.id}: ${error?.response?.status ?? error.message}`);
        enrichedPets.push({
          id: pet.id,
          name: pet.name,
          description: "",
          sourceType: "",
          sourceName: "",
          creatureId: null,
          creatureName: "",
          isCapturable: false,
          isTradable: false,
        });
      }

      if ((index + 1) % 100 === 0) {
        console.log(`${index + 1}/${pets.length} mascottes Blizzard`);
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));

  enrichedPets.sort((a, b) => a.id - b.id);

  return { enrichedPets, failedIds };
}

function extractWowheadListviewData(html) {
  const listviewIndex = html.indexOf("new Listview");
  const dataIndex = html.indexOf("data: ", listviewIndex);

  if (listviewIndex === -1 || dataIndex === -1) {
    return [];
  }

  const start = dataIndex + "data: ".length;
  let depth = 0;
  let inString = false;
  let escaping = false;

  for (let index = start; index < html.length; index += 1) {
    const char = html[index];

    if (inString) {
      if (escaping) {
        escaping = false;
      } else if (char === "\\") {
        escaping = true;
      } else if (char === "\"") {
        inString = false;
      }
      continue;
    }

    if (char === "\"") {
      inString = true;
    } else if (char === "[") {
      depth += 1;
    } else if (char === "]") {
      depth -= 1;
      if (depth === 0) {
        return JSON.parse(html.slice(start, index + 1));
      }
    }
  }

  return [];
}

async function fetchWowheadPetsByExpansion() {
  const bySpeciesId = new Map();
  const fetchStats = [];

  for (const expansion of expansions) {
    const url = `https://www.wowhead.com/fr/battle-pets?filter=4;${expansion.wowheadId};0`;
    const response = await axios.get(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 WoW100 metadata helper",
      },
      responseType: "text",
    });
    const rows = extractWowheadListviewData(response.data);

    fetchStats.push({
      expansion: expansion.key,
      source: url,
      count: rows.length,
    });

    for (const row of rows) {
      if (!row.species) continue;

      bySpeciesId.set(row.species, {
        expansion: expansion.key,
        expansionName: expansion.name,
        wowheadName: row.name,
        wowheadUrl: wowheadPetPageUrl(row.species),
        familyType: row.type ?? null,
        sourceCodes: row.source ?? [],
        locations: row.location ?? row.npc?.location ?? [],
      });
    }

    console.log(`${expansion.key}: ${rows.length} mascottes Wowhead`);
  }

  return { bySpeciesId, fetchStats };
}

async function loadManualMetadata() {
  try {
    const content = await fs.readFile(metadataPath, "utf8");
    const data = JSON.parse(content);

    return Object.fromEntries(data.map((item) => [item.blizzardId, item]));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
    return {};
  }
}

function buildLocationIndex(locationsCatalog) {
  const worldsByKey = new Map(
    (locationsCatalog.worlds ?? []).map((world) => [world.key, world]),
  );
  const continentsByKey = new Map(
    (locationsCatalog.continents ?? []).map((continent) => [
      continent.key,
      continent,
    ]),
  );
  const allByRef = new Map(
    (locationsCatalog.locations ?? []).map((location) => [
      location.ref,
      location,
    ]),
  );
  const byRef = new Map();
  const byWowheadZoneId = new Map();

  for (const location of locationsCatalog.locations ?? []) {
    const canonical =
      allByRef.get(location.canonicalRef ?? location.ref) ?? location;

    byRef.set(location.ref, canonical);
    byRef.set(canonical.ref, canonical);

    if (canonical.reviewStatus !== "reviewed") continue;

    const zoneIds = [
      ...(location.canonicalWowheadZoneIds ?? []),
      location.wowheadZoneId,
    ].filter(Number.isInteger);

    for (const zoneId of zoneIds) {
      byWowheadZoneId.set(zoneId, canonical);
    }
  }

  return {
    worldsByKey,
    continentsByKey,
    byRef,
    byWowheadZoneId,
  };
}

function describeLocation(location, locationIndex) {
  if (!location) return null;

  const world = locationIndex.worldsByKey.get(location.worldKey);
  const continent = locationIndex.continentsByKey.get(location.continentKey);

  return {
    ref: location.canonicalRef ?? location.ref,
    name: location.name,
    kind: location.kind,
    subzoneName: location.kind === "subzone" ? location.name : "",
    regionName: location.regionName,
    continentName: continent?.name ?? location.continentKey,
    worldName: world?.name ?? location.worldKey,
    path: location.path ?? [],
    pathLabel: location.pathLabel ?? "",
    wowheadZoneIds:
      location.canonicalWowheadZoneIds ??
      (Number.isInteger(location.wowheadZoneId)
        ? [location.wowheadZoneId]
        : []),
  };
}

function uniqueLocations(locations) {
  return [
    ...new Map(
      locations
        .filter(Boolean)
        .map((location) => [location.canonicalRef ?? location.ref, location]),
    ).values(),
  ];
}

function resolveManualLocation(manualMetadata, locationIndex, petId) {
  if (!manualMetadata.primaryLocationRef) return null;

  const requestedRefs = [
    manualMetadata.primaryLocationRef,
    ...(manualMetadata.locationRefs ?? []),
  ].filter(Boolean);
  const locations = uniqueLocations(
    requestedRefs.map((ref) => {
      const location = locationIndex.byRef.get(ref);
      if (!location) {
        throw new Error(
          `Localisation ${ref} introuvable pour la mascotte ${petId}`,
        );
      }
      return location;
    }),
  );
  const primary = locationIndex.byRef.get(manualMetadata.primaryLocationRef);

  if (!primary) {
    throw new Error(
      `Localisation principale ${manualMetadata.primaryLocationRef} introuvable pour la mascotte ${petId}`,
    );
  }

  return {
    primary,
    locations,
    status: manualMetadata.locationStatus ?? "confirmed",
    source: manualMetadata.locationSource ?? "manual_pet_metadata",
  };
}

function resolveWowheadLocations(wowheadMetadata, locationIndex) {
  const zoneIds = Array.isArray(wowheadMetadata?.locations)
    ? wowheadMetadata.locations
    : [];
  const locations = uniqueLocations(
    zoneIds.map((zoneId) => locationIndex.byWowheadZoneId.get(zoneId)),
  );

  if (!locations.length) return null;

  return {
    primary: locations[0],
    locations,
    status: "auto_assigned_wowhead_location",
    source: "wowhead_pet_location_ids_and_locations_reference_catalog",
  };
}

function resolvePetLocation(
  petId,
  manualMetadata,
  wowheadMetadata,
  locationIndex,
) {
  return (
    resolveManualLocation(manualMetadata, locationIndex, petId) ??
    resolveWowheadLocations(wowheadMetadata, locationIndex)
  );
}

function locationFields(locationResolution, locationIndex) {
  if (!locationResolution) {
    return {
      primaryLocationRef: null,
      locationRefs: [],
      locationAssignments: [],
      location: null,
      locationZone: "",
      zone: "",
      subzone: "",
      region: "",
      world: "",
    };
  }

  const selectedLocation = describeLocation(
    locationResolution.primary,
    locationIndex,
  );
  const selectedLocations = locationResolution.locations.map(
    (location, index) => {
      const description = describeLocation(location, locationIndex);

      return {
        locationRef: description.ref,
        role: index === 0 ? "primary_obtainment" : "alternative_obtainment",
        source: locationResolution.source,
        confidence: locationResolution.status,
      };
    },
  );
  const zone =
    selectedLocation.kind === "subzone"
      ? selectedLocation.regionName
      : selectedLocation.name;

  return {
    primaryLocationRef: selectedLocation.ref,
    locationRefs: selectedLocations.map((location) => location.locationRef),
    locationAssignments: selectedLocations,
    location: selectedLocation,
    locationZone: zone,
    zone,
    subzone: selectedLocation.subzoneName,
    region: selectedLocation.continentName,
    world: selectedLocation.worldName,
  };
}

function toWow100Item(pet, manualMetadata, wowheadMetadata, locationIndex) {
  const sourceLabel = firstNonEmpty(
    manualMetadata.source,
    sourceMap[pet.sourceType],
    pet.sourceName,
    "Source à vérifier",
  );
  const expansion = manualMetadata.expansion ?? wowheadMetadata?.expansion ?? "allPets";
  const wowheadUrl = firstNonEmpty(
    manualMetadata.externalUrl,
    wowheadMetadata?.wowheadUrl,
    wowheadPetPageUrl(pet.id),
  );
  const resolvedLocation = locationFields(
    resolvePetLocation(pet.id, manualMetadata, wowheadMetadata, locationIndex),
    locationIndex,
  );
  const hasLocation = Boolean(
    manualMetadata.primaryLocationRef ?? resolvedLocation.primaryLocationRef,
  );

  return {
    id: `pet_${pet.id}`,
    name: pet.name,
    description: pet.description,
    category: "pets",
    expansion,
    ...(hasLocation
      ? {
          primaryLocationRef:
            manualMetadata.primaryLocationRef ??
            resolvedLocation.primaryLocationRef,
          locationRefs:
            manualMetadata.locationRefs ?? resolvedLocation.locationRefs,
          locationAssignments: resolvedLocation.locationAssignments,
          location: resolvedLocation.location,
          locationZone: manualMetadata.zone ?? resolvedLocation.locationZone,
          zone: manualMetadata.zone ?? resolvedLocation.zone,
          subzone: manualMetadata.subzone ?? resolvedLocation.subzone,
          region: manualMetadata.region ?? resolvedLocation.region,
          world: manualMetadata.world ?? resolvedLocation.world,
        }
      : { zone: manualMetadata.zone ?? "" }),
    instance: manualMetadata.instance ?? sourceLabel,
    source: firstNonEmpty(manualMetadata.sourceName, pet.sourceName, sourceLabel),
    ...(Array.isArray(manualMetadata.tags) && manualMetadata.tags.length > 0
      ? { tags: manualMetadata.tags }
      : {}),
    ...(manualMetadata.condition ? { condition: manualMetadata.condition } : {}),
    sourceType: pet.sourceType || "UNKNOWN",
    sourceName: pet.sourceName || "",
    groupRequired: manualMetadata.groupRequired ?? false,
    weeklyLockout: manualMetadata.weeklyLockout ?? pet.sourceType === "DROP",
    blizzardId: pet.id,
    creatureId: pet.creatureId,
    creatureName: pet.creatureName,
    isCapturable: pet.isCapturable,
    isTradable: pet.isTradable,
    boss: manualMetadata.boss ?? "",
    externalUrl: wowheadUrl,
    wowhead: wowheadMetadata ?? null,
    mamytwink: manualMetadata.mamytwink ?? null,
  };
}

async function main() {
  const token = useOffline ? null : await getToken();
  const catalog = useOffline
    ? await loadJson(rawCatalogPath, { pets: [] })
    : await fetchBlizzardJson(
        "https://eu.api.blizzard.com/data/wow/pet/index",
        token,
      );

  console.log(`Mascottes Blizzard trouvées : ${catalog.pets.length}`);

  await fs.mkdir(generatedDir, { recursive: true });
  await fs.mkdir(petDataDir, { recursive: true });

  if (!useOffline) {
    await fs.writeFile(
      rawCatalogPath,
      `${JSON.stringify(catalog, null, 2)}\n`,
      "utf8",
    );
  }

  const existingEnrichedPets = await loadExistingEnrichedPets();

  const [petDetails, wowhead, manualById, locationsCatalog] = await Promise.all([
    useOffline
      ? {
          enrichedPets: [...existingEnrichedPets.values()].sort(
            (left, right) => left.id - right.id,
          ),
          failedIds: [],
        }
      : fetchPetDetails(catalog.pets, token, existingEnrichedPets),
    useOffline
      ? loadJson(wowheadExpansionIndexPath, { fetchStats: [], pets: {} }).then(
          (data) => ({
            fetchStats: data.fetchStats ?? [],
            bySpeciesId: new Map(
              Object.entries(data.pets ?? {}).map(([id, pet]) => [
                Number(id),
                pet,
              ]),
            ),
          }),
        )
      : fetchWowheadPetsByExpansion(),
    loadManualMetadata(),
    loadJson(locationsCatalogPath, { worlds: [], continents: [], locations: [] }),
  ]);
  const { enrichedPets, failedIds } = petDetails;
  const locationIndex = buildLocationIndex(locationsCatalog);

  await fs.writeFile(
    enrichedCatalogPath,
    `${JSON.stringify(enrichedPets, null, 2)}\n`,
    "utf8",
  );

  const wowheadExpansionIndex = Object.fromEntries(
    [...wowhead.bySpeciesId.entries()].sort(([left], [right]) => left - right),
  );

  if (!useOffline) {
    await fs.writeFile(
      wowheadExpansionIndexPath,
      `${JSON.stringify(
        {
          generatedAt: new Date().toISOString(),
          source: "https://www.wowhead.com/fr/battle-pets",
          fetchStats: wowhead.fetchStats,
          pets: wowheadExpansionIndex,
        },
        null,
        2,
      )}\n`,
      "utf8",
    );
  }

  const wow100Draft = enrichedPets.map((pet) =>
    toWow100Item(
      pet,
      manualById[pet.id] ?? {},
      wowhead.bySpeciesId.get(pet.id),
      locationIndex,
    ),
  );

  wow100Draft.sort((a, b) => {
    const expansionCompare = String(a.expansion ?? "").localeCompare(
      String(b.expansion ?? ""),
    );
    if (expansionCompare !== 0) return expansionCompare;

    const instanceCompare = String(a.instance ?? "").localeCompare(
      String(b.instance ?? ""),
    );
    if (instanceCompare !== 0) return instanceCompare;

    return String(a.name ?? "").localeCompare(String(b.name ?? ""));
  });

  await fs.writeFile(
    path.join(generatedDir, "pets_wow100_draft.json"),
    `${JSON.stringify(wow100Draft, null, 2)}\n`,
    "utf8",
  );

  for (const expansion of expansions) {
    const items = wow100Draft.filter((pet) => pet.expansion === expansion.key);

    await fs.writeFile(
      path.join(petDataDir, `${expansion.key}_pets.json`),
      `${JSON.stringify(items, null, 2)}\n`,
      "utf8",
    );

    console.log(`${expansion.key}_pets.json : ${items.length} mascottes`);
  }

  const unclassified = wow100Draft.filter((pet) => pet.expansion === "allPets");

  console.log(
    JSON.stringify(
      {
        blizzardPets: catalog.pets.length,
        enrichedPets: enrichedPets.length,
        failedIds,
        classifiedByWowheadOrManual: wow100Draft.length - unclassified.length,
        unclassified: unclassified.length,
        localized: wow100Draft.filter((pet) => pet.primaryLocationRef).length,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error?.response?.status ?? error.message);
  process.exitCode = 1;
});
