import axios from "axios";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");

const outputPath = path.join(
  repoRoot,
  "assets/generated/mamytwink_mount_candidates.json",
);
const metadataDraftPath = path.join(
  repoRoot,
  "assets/generated/mounts_metadata_mamytwink_draft.json",
);
const blizzardCatalogPath = path.join(
  repoRoot,
  "assets/generated/mounts_catalog_enriched.json",
);
const existingMetadataPath = path.join(
  repoRoot,
  "assets/data/metadata/mounts_metadata.json",
);

const extensions = [
  { id: 1, key: "vanilla", name: "WoW Vanilla" },
  { id: 2, key: "tbc", name: "Burning Crusade" },
  { id: 3, key: "wrath", name: "Wrath of the Lich King" },
  { id: 4, key: "cataclysm", name: "Cataclysm" },
  { id: 5, key: "mop", name: "Mists of Pandaria" },
  { id: 6, key: "wod", name: "Warlords of Draenor" },
  { id: 7, key: "legion", name: "Legion" },
  { id: 8, key: "bfa", name: "Battle for Azeroth" },
  { id: 12, key: "shadowlands", name: "Shadowlands" },
  { id: 13, key: "dragonflight", name: "Dragonflight" },
  { id: 14, key: "warWithin", name: "The War Within" },
  { id: 15, key: "midnight", name: "Midnight" },
];

const acquisitionPrefixes = [
  "renes de ",
  "renes d ",
  "renes du ",
  "renes des ",
  "bride de ",
  "bride d ",
  "bride du ",
  "bride des ",
  "cle de ",
  "cle d ",
  "cle du ",
  "cor de ",
  "cor d ",
  "cor du ",
  "laisse de ",
  "harnais de ",
  "selle de ",
];

function decodeHtml(value) {
  return value
    .replace(/&nbsp;/g, " ")
    .replace(/&#039;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

function stripTags(value) {
  return decodeHtml(value.replace(/<[^>]+>/g, " "))
    .replace(/\s+/g, " ")
    .trim();
}

function normalizeName(value) {
  return String(value ?? "")
    .toLocaleLowerCase("fr-FR")
    .replace(/[’`]/g, "'")
    .replace(/œ/g, "oe")
    .replace(/æ/g, "ae")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");
}

function withoutAcquisitionPrefix(normalizedName) {
  for (const prefix of acquisitionPrefixes) {
    if (normalizedName.startsWith(prefix)) {
      return normalizedName.slice(prefix.length).trim();
    }
  }

  return normalizedName;
}

function getPageCount(html, extensionId) {
  const pageMatches = [
    ...html.matchAll(
      new RegExp(`href="/montures/(\\d+)\\?extension=${extensionId}"`, "g"),
    ),
  ];
  const pages = pageMatches.map((match) => Number(match[1]));

  return Math.max(1, ...pages);
}

function getResultCount(html) {
  const text = stripTags(html);
  const match = text.match(/(\d+)\s+montures trouv/);

  return match ? Number(match[1]) : 0;
}

function getFaction(sourceHtml) {
  if (sourceHtml.includes("icone alliance")) {
    return "Alliance";
  }

  if (sourceHtml.includes("icone horde")) {
    return "Horde";
  }

  return "Neutre";
}

function parseRows(html, extension) {
  const rows = [...html.matchAll(/<tr>\s*([\s\S]*?)\s*<\/tr>/g)];

  return rows
    .map((rowMatch) => {
      const rowHtml = rowMatch[1];
      const linkMatch = rowHtml.match(
        /<a href="(\/montures\/[^"]+)"[^>]*>([\s\S]*?)<\/a>/,
      );

      if (!linkMatch) {
        return null;
      }

      const cells = rowHtml.split(/<td[^>]*>/).slice(1);

      if (cells.length < 5) {
        return null;
      }

      return {
        mamytwinkName: stripTags(linkMatch[2]),
        mamytwinkSlug: linkMatch[1].replace("/montures/", ""),
        mamytwinkUrl: `https://www.mamytwink.com${linkMatch[1]}`,
        expansion: extension.key,
        extensionName: extension.name,
        type: stripTags(cells[1]),
        difficulty: stripTags(cells[2]).replace(/^.*?\s/, ""),
        source: stripTags(cells[3]),
        faction: getFaction(cells[3]),
        comments: Number(stripTags(cells[4])) || 0,
      };
    })
    .filter(Boolean);
}

function addToIndex(index, key, mount) {
  if (!key) {
    return;
  }

  if (!index.has(key)) {
    index.set(key, []);
  }

  index.get(key).push(mount);
}

function buildBlizzardIndexes(blizzardMounts) {
  const exact = new Map();
  const stripped = new Map();

  for (const mount of blizzardMounts) {
    const normalized = normalizeName(mount.name);
    addToIndex(exact, normalized, mount);
    addToIndex(stripped, withoutAcquisitionPrefix(normalized), mount);
  }

  return { exact, stripped };
}

function findMatch(row, indexes) {
  const normalized = normalizeName(row.mamytwinkName);
  const exactMatches = indexes.exact.get(normalized) ?? [];

  if (exactMatches.length === 1) {
    return {
      matchType: "exactName",
      confidence: "high",
      matches: exactMatches,
    };
  }

  if (exactMatches.length > 1) {
    return {
      matchType: "exactName",
      confidence: "ambiguous",
      matches: exactMatches,
    };
  }

  const strippedMatches =
    indexes.stripped.get(withoutAcquisitionPrefix(normalized)) ?? [];

  if (strippedMatches.length === 1) {
    return {
      matchType: "strippedAcquisitionPrefix",
      confidence: "medium",
      matches: strippedMatches,
    };
  }

  if (strippedMatches.length > 1) {
    return {
      matchType: "strippedAcquisitionPrefix",
      confidence: "ambiguous",
      matches: strippedMatches,
    };
  }

  return {
    matchType: "none",
    confidence: "none",
    matches: [],
  };
}

function toCandidate(row, match) {
  const mount = match.matches[0];

  return {
    blizzardId: mount.id,
    blizzardName: mount.name,
    mamytwinkName: row.mamytwinkName,
    mamytwinkUrl: row.mamytwinkUrl,
    expansion: row.expansion,
    extensionName: row.extensionName,
    type: row.type,
    difficulty: row.difficulty,
    source: row.source,
    faction: row.faction,
    comments: row.comments,
    matchType: match.matchType,
    confidence: match.confidence,
  };
}

function toUnmatched(row, match) {
  return {
    mamytwinkName: row.mamytwinkName,
    mamytwinkUrl: row.mamytwinkUrl,
    expansion: row.expansion,
    extensionName: row.extensionName,
    type: row.type,
    difficulty: row.difficulty,
    source: row.source,
    faction: row.faction,
    comments: row.comments,
    matchType: match.matchType,
    possibleBlizzardMatches: match.matches.map((mount) => ({
      blizzardId: mount.id,
      blizzardName: mount.name,
    })),
  };
}

function summarizeByExpansion(rows) {
  return Object.fromEntries(
    extensions.map((extension) => [
      extension.key,
      rows.filter((row) => row.expansion === extension.key).length,
    ]),
  );
}

function inferCategory(source) {
  const normalizedSource = normalizeName(source);

  if (normalizedSource.startsWith("butin")) {
    return "drop";
  }

  if (normalizedSource.includes("vendeur")) {
    return "vendor";
  }

  if (normalizedSource.includes("reputation")) {
    return "reputation";
  }

  if (normalizedSource.includes("quete")) {
    return "quest";
  }

  if (normalizedSource.includes("haut fait")) {
    return "achievement";
  }

  if (normalizedSource.includes("metier") || normalizedSource.includes("ingenierie")) {
    return "profession";
  }

  if (normalizedSource.includes("evenement mondial")) {
    return "world_event";
  }

  if (normalizedSource.includes("cartes a collectionner")) {
    return "tcg";
  }

  if (normalizedSource.includes("boutique")) {
    return "store";
  }

  if (normalizedSource.includes("pvp")) {
    return "pvp";
  }

  if (normalizedSource.includes("promotion blizzard")) {
    return "promotion";
  }

  if (normalizedSource.includes("exploration des iles")) {
    return "island_expedition";
  }

  if (normalizedSource.includes("secret")) {
    return "secret";
  }

  if (normalizedSource.includes("non implemente")) {
    return "not_implemented";
  }

  if (normalizedSource.includes("retire")) {
    return "retired";
  }

  if (normalizedSource.includes("congregation")) {
    return "covenant";
  }

  if (normalizedSource.includes("comptoir")) {
    return "trading_post";
  }

  if (normalizedSource.includes("inconnu")) {
    return "unknown";
  }

  return "other";
}

function toMetadataDraft(candidate) {
  return {
    blizzardId: candidate.blizzardId,
    expansion: candidate.expansion,
    category: inferCategory(candidate.source),
    mamytwink: {
      name: candidate.mamytwinkName,
      url: candidate.mamytwinkUrl,
      type: candidate.type,
      difficulty: candidate.difficulty,
      source: candidate.source,
      faction: candidate.faction,
      matchType: candidate.matchType,
      confidence: candidate.confidence,
    },
  };
}

async function fetchHtml(url) {
  const response = await axios.get(url, {
    headers: {
      "User-Agent": "WoW100 metadata helper (+manual verification)",
    },
    responseType: "text",
  });

  return response.data;
}

async function delay(milliseconds) {
  await new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function fetchExtensionRows(extension) {
  const firstUrl = `https://www.mamytwink.com/montures?extension=${extension.id}`;
  const firstHtml = await fetchHtml(firstUrl);
  const pageCount = getPageCount(firstHtml, extension.id);
  const expectedCount = getResultCount(firstHtml);
  const rows = parseRows(firstHtml, extension);

  for (let page = 2; page <= pageCount; page += 1) {
    await delay(250);
    const html = await fetchHtml(
      `https://www.mamytwink.com/montures/${page}?extension=${extension.id}`,
    );
    rows.push(...parseRows(html, extension));
  }

  console.log(
    `${extension.key}: ${rows.length}/${expectedCount} rows from ${pageCount} page(s)`,
  );

  return {
    rows,
    expectedCount,
    pageCount,
  };
}

async function main() {
  const blizzardMounts = JSON.parse(
    await fs.readFile(blizzardCatalogPath, "utf8"),
  );
  const existingMetadata = JSON.parse(
    await fs.readFile(existingMetadataPath, "utf8"),
  );
  const existingMetadataIds = new Set(
    existingMetadata.map((item) => item.blizzardId),
  );
  const indexes = buildBlizzardIndexes(blizzardMounts);
  const mamytwinkRows = [];
  const fetchStats = [];

  for (const extension of extensions) {
    const result = await fetchExtensionRows(extension);
    mamytwinkRows.push(...result.rows);
    fetchStats.push({
      extension: extension.key,
      extensionName: extension.name,
      expectedCount: result.expectedCount,
      parsedCount: result.rows.length,
      pageCount: result.pageCount,
    });
  }

  const candidates = [];
  const unmatchedMamytwink = [];
  const ambiguousMamytwink = [];

  for (const row of mamytwinkRows) {
    const match = findMatch(row, indexes);

    if (match.confidence === "high" || match.confidence === "medium") {
      candidates.push(toCandidate(row, match));
    } else if (match.confidence === "ambiguous") {
      ambiguousMamytwink.push(toUnmatched(row, match));
    } else {
      unmatchedMamytwink.push(toUnmatched(row, match));
    }
  }

  const matchedIds = new Set(candidates.map((candidate) => candidate.blizzardId));
  const unmatchedBlizzard = blizzardMounts
    .filter((mount) => !matchedIds.has(mount.id))
    .map((mount) => ({
      blizzardId: mount.id,
      blizzardName: mount.name,
      sourceType: mount.sourceType || "UNKNOWN",
      sourceName: mount.sourceName || "",
      faction: mount.faction || "",
    }));

  const output = {
    generatedAt: new Date().toISOString(),
    source: "https://www.mamytwink.com/montures",
    note:
      "Manual verification helper only. Blizzard remains the catalog and ownership source.",
    summary: {
      blizzardMounts: blizzardMounts.length,
      mamytwinkRows: mamytwinkRows.length,
      candidates: candidates.length,
      highConfidence: candidates.filter(
        (candidate) => candidate.confidence === "high",
      ).length,
      mediumConfidence: candidates.filter(
        (candidate) => candidate.confidence === "medium",
      ).length,
      ambiguousMamytwink: ambiguousMamytwink.length,
      unmatchedMamytwink: unmatchedMamytwink.length,
      unmatchedBlizzard: unmatchedBlizzard.length,
      metadataDraftEntries: candidates.filter(
        (candidate) => !existingMetadataIds.has(candidate.blizzardId),
      ).length,
      mamytwinkByExpansion: summarizeByExpansion(mamytwinkRows),
      candidatesByExpansion: summarizeByExpansion(candidates),
    },
    fetchStats,
    candidates,
    ambiguousMamytwink,
    unmatchedMamytwink,
    unmatchedBlizzard,
  };

  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  await fs.writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");
  await fs.writeFile(
    metadataDraftPath,
    `${JSON.stringify(
      candidates
        .filter((candidate) => !existingMetadataIds.has(candidate.blizzardId))
        .sort((a, b) => a.blizzardId - b.blizzardId)
        .map(toMetadataDraft),
      null,
      2,
    )}\n`,
    "utf8",
  );

  console.log(`Saved ${outputPath}`);
  console.log(`Saved ${metadataDraftPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
