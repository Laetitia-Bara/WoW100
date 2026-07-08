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
    const content = await fs.readFile(
      path.join(generatedDir, "pets_catalog_enriched.json"),
      "utf8",
    );
    const data = JSON.parse(content);

    return new Map(data.map((pet) => [pet.id, pet]));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
    return new Map();
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
    const url = `https://www.wowhead.com/battle-pets?filter=4;${expansion.wowheadId};0`;
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
        wowheadUrl: `https://www.wowhead.com/battle-pet/${row.species}`,
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

function toWow100Item(pet, manualMetadata, wowheadMetadata) {
  const sourceLabel = firstNonEmpty(
    manualMetadata.source,
    sourceMap[pet.sourceType],
    pet.sourceName,
    "Source à vérifier",
  );
  const expansion = manualMetadata.expansion ?? wowheadMetadata?.expansion ?? "allPets";

  return {
    id: `pet_${pet.id}`,
    name: pet.name,
    description: pet.description,
    category: "pets",
    expansion,
    zone: manualMetadata.zone ?? "",
    instance: manualMetadata.instance ?? sourceLabel,
    source: firstNonEmpty(manualMetadata.sourceName, pet.sourceName, sourceLabel),
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
    externalUrl:
      manualMetadata.externalUrl ??
      wowheadMetadata?.wowheadUrl ??
      `https://www.wowhead.com/battle-pet/${pet.id}`,
    wowhead: wowheadMetadata ?? null,
    mamytwink: manualMetadata.mamytwink ?? null,
  };
}

async function main() {
  const token = await getToken();
  const catalog = await fetchBlizzardJson(
    "https://eu.api.blizzard.com/data/wow/pet/index",
    token,
  );

  console.log(`Mascottes Blizzard trouvées : ${catalog.pets.length}`);

  await fs.mkdir(generatedDir, { recursive: true });
  await fs.mkdir(petDataDir, { recursive: true });

  await fs.writeFile(
    path.join(generatedDir, "pets_catalog_raw.json"),
    `${JSON.stringify(catalog, null, 2)}\n`,
    "utf8",
  );

  const existingEnrichedPets = await loadExistingEnrichedPets();

  const [{ enrichedPets, failedIds }, wowhead, manualById] = await Promise.all([
    fetchPetDetails(catalog.pets, token, existingEnrichedPets),
    fetchWowheadPetsByExpansion(),
    loadManualMetadata(),
  ]);

  await fs.writeFile(
    path.join(generatedDir, "pets_catalog_enriched.json"),
    `${JSON.stringify(enrichedPets, null, 2)}\n`,
    "utf8",
  );

  const wowheadExpansionIndex = Object.fromEntries(
    [...wowhead.bySpeciesId.entries()].sort(([left], [right]) => left - right),
  );

  await fs.writeFile(
    path.join(generatedDir, "pets_wowhead_expansion_index.json"),
    `${JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        source: "https://www.wowhead.com/battle-pets",
        fetchStats: wowhead.fetchStats,
        pets: wowheadExpansionIndex,
      },
      null,
      2,
    )}\n`,
    "utf8",
  );

  const wow100Draft = enrichedPets.map((pet) =>
    toWow100Item(pet, manualById[pet.id] ?? {}, wowhead.bySpeciesId.get(pet.id)),
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
