import axios from "axios";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
const generatedDir = path.join(repoRoot, "assets/generated");

const wowheadZonesUrl = "https://www.wowhead.com/fr/zones";
const wowheadGlobalDataUrl =
  "https://nether.wowhead.com/fr/data/global?dv=82&db=1781703883&versionsSig=8be6282e18bb8e495a08a00edea3cb26";

const expansionInfo = {
  0: { key: "vanilla", name: "Vanilla", basePatch: "1.0.0" },
  1: {
    key: "the-burning-crusade",
    name: "The Burning Crusade",
    basePatch: "2.0.1",
  },
  2: {
    key: "wrath-of-the-lich-king",
    name: "Wrath of the Lich King",
    basePatch: "3.0.2",
  },
  3: { key: "cataclysm", name: "Cataclysm", basePatch: "4.0.3" },
  4: {
    key: "mists-of-pandaria",
    name: "Mists of Pandaria",
    basePatch: "5.0.4",
  },
  5: {
    key: "warlords-of-draenor",
    name: "Warlords of Draenor",
    basePatch: "6.0.2",
  },
  6: { key: "legion", name: "Legion", basePatch: "7.0.3" },
  7: {
    key: "battle-for-azeroth",
    name: "Battle for Azeroth",
    basePatch: "8.0.1",
  },
  8: { key: "shadowlands", name: "Shadowlands", basePatch: "9.0.1" },
  9: { key: "dragonflight", name: "Dragonflight", basePatch: "10.0.2" },
  10: { key: "the-war-within", name: "The War Within", basePatch: "11.0.0" },
  11: { key: "midnight", name: "Midnight", basePatch: "12.0.0" },
  12: { key: "the-last-titan", name: "The Last Titan", basePatch: null },
};

const territoryInfo = {
  0: "Alliance",
  1: "Horde",
  2: "Contesté",
  3: "Sanctuaire",
  4: "JcJ",
  5: "JcJ mondial",
};

const geographicRegionIds = new Set([
  0, // Royaumes de l'Est
  1, // Kalimdor
  8, // Outreterre
  10, // Norfendre
  11, // Le Maelstrom
  12, // Pandarie
  13, // Draenor
  14, // Les Iles Brisees
  15, // Zandalar
  16, // Kul Tiras
  17, // Ombreterre
  18, // Iles aux Dragons
  19, // Khaz Algar
  20, // Quel'Thalas
]);

function normalizeName(value) {
  return String(value ?? "")
    .toLocaleLowerCase("fr-FR")
    .replace(/[’`]/g, "'")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function extractListview(html) {
  const listviewsMatch = html.match(
    /<script type="application\/json" id="data\.page\.listPage\.listviews">([\s\S]*?)<\/script>/,
  );

  if (!listviewsMatch) {
    throw new Error("Impossible de trouver data.page.listPage.listviews");
  }

  const listviews = JSON.parse(listviewsMatch[1]);
  const zoneListview = listviews.find((listview) => listview.id === "zones");

  if (!zoneListview?.data?.length) {
    throw new Error("Le tableau Wowhead des zones est vide ou introuvable");
  }

  return zoneListview;
}

function extractPageData(script, key) {
  const marker = `WH.setPageData("${key}",`;
  const markerIndex = script.indexOf(marker);

  if (markerIndex === -1) {
    throw new Error(`Impossible de trouver WH.setPageData("${key}")`);
  }

  const start = markerIndex + marker.length;
  let depth = 0;
  let inString = false;
  let escaping = false;

  for (let index = start; index < script.length; index += 1) {
    const char = script[index];

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
    } else if (char === "{" || char === "[") {
      depth += 1;
    } else if (char === "}" || char === "]") {
      depth -= 1;
      if (depth === 0) {
        return JSON.parse(script.slice(start, index + 1));
      }
    }
  }

  throw new Error(`Impossible de parser WH.setPageData("${key}")`);
}

async function fetchText(url) {
  const response = await axios.get(url, {
    headers: {
      "User-Agent": "Mozilla/5.0 WoW100 metadata helper",
    },
    responseType: "text",
  });

  return response.data;
}

function toNullableNumber(value) {
  return Number.isFinite(value) ? value : null;
}

function buildZone(row, maps) {
  const expansion = expansionInfo[row.expansion] ?? {
    key: `unknown-${row.expansion}`,
    name: "Inconnue",
    basePatch: null,
  };
  const categoryName = maps.categoryNames[String(row.category)] ?? "Inconnu";
  const isGeographicRegion = geographicRegionIds.has(row.category);

  return {
    id: row.id,
    name: row.name,
    normalizedName: normalizeName(row.name),
    wowheadUrl: `https://www.wowhead.com/fr/zone=${row.id}`,
    wowheadCategoryId: row.category,
    wowheadCategoryName: categoryName,
    isGeographicRegion,
    geographicRegionId: isGeographicRegion ? row.category : null,
    geographicRegionName: isGeographicRegion ? categoryName : null,
    expansionId: row.expansion,
    expansionKey: expansion.key,
    expansionName: expansion.name,
    expansionBasePatch: expansion.basePatch,
    patch: null,
    patchSource: "not_in_wowhead_zone_list",
    instanceTypeId: row.instance,
    instanceTypeName: maps.instanceTypeNames[String(row.instance)] ?? "Inconnu",
    territoryId: row.territory,
    territoryName: territoryInfo[row.territory] ?? "Inconnu",
    minLevel: toNullableNumber(row.minlevel),
    maxLevel: toNullableNumber(row.maxlevel),
    requiredLevel: toNullableNumber(row.reqlevel),
    heroicLevel: toNullableNumber(row.heroicLevel),
    lfgRequiredLevel: toNullableNumber(row.lfgReqLevel),
    players: toNullableNumber(row.nplayers),
    worldPvp: Boolean(row.worldpvp),
    popularity: toNullableNumber(row.popularity),
  };
}

function buildAudit(zones, maps) {
  const ids = new Set();
  const duplicateIds = [];
  const unknownContinents = new Set();
  const unknownInstanceTypes = new Set();
  const unknownExpansions = new Set();
  const byExpansion = {};
  const byContinent = {};
  const byWowheadCategory = {};
  const byInstanceType = {};

  for (const zone of zones) {
    if (ids.has(zone.id)) {
      duplicateIds.push(zone.id);
    }
    ids.add(zone.id);

    if (!maps.categoryNames[String(zone.wowheadCategoryId)]) {
      unknownContinents.add(zone.wowheadCategoryId);
    }
    if (!maps.instanceTypeNames[String(zone.instanceTypeId)]) {
      unknownInstanceTypes.add(zone.instanceTypeId);
    }
    if (!expansionInfo[zone.expansionId]) {
      unknownExpansions.add(zone.expansionId);
    }

    byExpansion[zone.expansionKey] = (byExpansion[zone.expansionKey] ?? 0) + 1;
    if (zone.geographicRegionName) {
      byContinent[zone.geographicRegionName] =
        (byContinent[zone.geographicRegionName] ?? 0) + 1;
    }
    byWowheadCategory[zone.wowheadCategoryName] =
      (byWowheadCategory[zone.wowheadCategoryName] ?? 0) + 1;
    byInstanceType[zone.instanceTypeName] =
      (byInstanceType[zone.instanceTypeName] ?? 0) + 1;
  }

  return {
    rowCount: zones.length,
    uniqueIds: ids.size,
    duplicateIds,
    unknownContinents: [...unknownContinents],
    unknownInstanceTypes: [...unknownInstanceTypes],
    unknownExpansions: [...unknownExpansions],
    zonesWithoutPatch: zones.filter((zone) => !zone.patch).length,
    zonesWithoutGeographicRegion: zones.filter(
      (zone) => !zone.geographicRegionName,
    ).length,
    note:
      "Wowhead expose extension, categorie, territoire et type d'instance dans la liste des zones. La categorie peut etre une region geographique ou un groupe de contenu comme Donjons/Raids/Scenarios; geographicRegionName reste null dans ce cas. Le patch precis par zone n'est pas present dans cette liste; expansionBasePatch est seulement le patch de lancement de l'extension.",
    byExpansion,
    byGeographicRegion: byContinent,
    byWowheadCategory,
    byInstanceType,
  };
}

async function main() {
  const [zonesHtml, globalData] = await Promise.all([
    fetchText(wowheadZonesUrl),
    fetchText(wowheadGlobalDataUrl),
  ]);

  const zoneListview = extractListview(zonesHtml);
  const maps = {
    categoryNames: extractPageData(globalData, "wow.area.categoryNames"),
    instanceTypeNames: extractPageData(globalData, "wow.area.instanceTypeNames"),
  };

  const zones = zoneListview.data
    .map((row) => buildZone(row, maps))
    .sort((a, b) => a.id - b.id);

  const audit = buildAudit(zones, maps);
  const catalog = {
    source: {
      name: "Wowhead Zones",
      url: wowheadZonesUrl,
      gameVersion: "12.0.7",
      locale: "fr_FR",
      rowCount: zones.length,
    },
    columns: {
      wowheadCategoryName:
        "Libelle de categorie Wowhead. Peut etre une region geographique ou un groupe de contenu.",
      geographicRegionName:
        "Region/continent uniquement quand la categorie Wowhead est geographique. Null pour Donjons, Raids, Scenarios, Arene, Champs de bataille et Autre.",
      patch:
        "Patch exact de la zone. Null tant que Wowhead ne l'expose pas dans la liste structuree.",
      expansionBasePatch:
        "Patch de lancement de l'extension, utile pour grouper sans pretendre connaitre le patch exact de chaque zone.",
    },
    maps: {
      wowheadCategories: maps.categoryNames,
      geographicRegionIds: [...geographicRegionIds].sort((a, b) => a - b),
      instanceTypes: maps.instanceTypeNames,
      territories: territoryInfo,
      expansions: expansionInfo,
    },
    zones,
  };

  await fs.mkdir(generatedDir, { recursive: true });
  await Promise.all([
    fs.writeFile(
      path.join(generatedDir, "zones_wowhead_catalog.json"),
      `${JSON.stringify(catalog, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      path.join(generatedDir, "zones_wowhead_audit_report.json"),
      `${JSON.stringify(audit, null, 2)}\n`,
      "utf8",
    ),
  ]);

  console.log(
    [
      `${zones.length} zones Wowhead ecrites`,
      `${audit.uniqueIds} IDs uniques`,
      `${audit.unknownContinents.length} continents inconnus`,
      `${audit.unknownInstanceTypes.length} types inconnus`,
      `${audit.unknownExpansions.length} extensions inconnues`,
    ].join(" | "),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
