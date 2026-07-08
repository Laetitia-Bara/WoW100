import axios from "axios";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
const generatedDir = path.join(repoRoot, "assets/generated");
const metadataDir = path.join(repoRoot, "assets/data/metadata");

const cachePath = path.join(generatedDir, "wowhead_patch_audit_cache.json");
const reportPath = path.join(generatedDir, "wowhead_patch_audit_report.json");

const categoryUrls = {
  mount: (id) => `https://www.wowhead.com/mount/${id}`,
  pet: (id) => `https://www.wowhead.com/battle-pet/${id}`,
  achievement: (id) => `https://www.wowhead.com/achievement=${id}`,
};

const mountItemExpansionFilters = [
  { key: "vanilla", wowheadId: 1 },
  { key: "tbc", wowheadId: 2 },
  { key: "wrath", wowheadId: 3 },
  { key: "cataclysm", wowheadId: 4 },
  { key: "mop", wowheadId: 5 },
  { key: "wod", wowheadId: 6 },
  { key: "legion", wowheadId: 7 },
  { key: "bfa", wowheadId: 8 },
  { key: "shadowlands", wowheadId: 9 },
  { key: "dragonflight", wowheadId: 10 },
  { key: "warWithin", wowheadId: 11 },
  { key: "midnight", wowheadId: 12 },
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
  "cor de ",
  "cor d ",
  "cor du ",
  "sifflet de ",
  "sifflet d ",
  "sifflet du ",
  "harnais de ",
  "harnais d ",
  "harnais du ",
  "laisse de ",
  "laisse d ",
  "selle de ",
  "selle d ",
  "cle de ",
  "cle d ",
  "cristal de resonance ",
  "cryptogramme fractal du ",
  "cryptogramme fractal de ",
];

const sourceFiles = {
  mountsCatalog: path.join(generatedDir, "mounts_catalog_enriched.json"),
  mountManualMetadata: path.join(metadataDir, "mounts_metadata.json"),
  mountWowheadOverrides: path.join(metadataDir, "mounts_wowhead_overrides.json"),
  mountMamytwinkDraft: path.join(generatedDir, "mounts_metadata_mamytwink_draft.json"),
  mountMamytwinkCandidates: path.join(generatedDir, "mamytwink_mount_candidates.json"),
  petsDraft: path.join(generatedDir, "pets_wow100_draft.json"),
  achievementsDraft: path.join(generatedDir, "achievements_wow100_draft.json"),
};

const args = parseArgs(process.argv.slice(2));
const selectedKinds = new Set(
  (args.kinds ?? "mount,pet,achievement")
    .split(",")
    .map((kind) => kind.trim())
    .filter(Boolean),
);
const maxPages = Number(args.maxPages ?? 0);
const concurrency = Number(args.concurrency ?? 6);
const refresh = args.refresh === "true" || args.refresh === true;
const offline = args.offline === "true" || args.offline === true;

function parseArgs(values) {
  const parsed = {};

  for (const value of values) {
    if (!value.startsWith("--")) continue;

    const [key, raw = true] = value.slice(2).split("=");
    parsed[key] = raw;
  }

  return parsed;
}

async function loadJson(filePath, fallback) {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") return fallback;
    throw error;
  }
}

function byBlizzardId(rows) {
  return new Map(
    rows
      .filter((row) => Number.isInteger(row.blizzardId))
      .map((row) => [row.blizzardId, row]),
  );
}

function firstNonEmpty(...values) {
  return values.find((value) => typeof value === "string" && value.trim()) ?? "";
}

function patchToExpansion(patch) {
  if (patch == null || patch === "") return null;
  if (patch === 0 || patch === "0") return "vanilla";

  const major = Number(String(patch).split(".")[0]);

  if (!Number.isFinite(major)) return null;
  if (major <= 1) return "vanilla";
  if (major === 2) return "tbc";
  if (major === 3) return "wrath";
  if (major === 4) return "cataclysm";
  if (major === 5) return "mop";
  if (major === 6) return "wod";
  if (major === 7) return "legion";
  if (major === 8) return "bfa";
  if (major === 9) return "shadowlands";
  if (major === 10) return "dragonflight";
  if (major === 11) return "warWithin";
  if (major === 12) return "midnight";

  return null;
}

function normalizeExpansion(expansion) {
  if (!expansion) return null;
  if (expansion === "allMounts" || expansion === "allPets" || expansion === "allAchievements") {
    return null;
  }

  return expansion;
}

function normalizeName(value) {
  return String(value ?? "")
    .toLocaleLowerCase("fr-FR")
    .replace(/[’`]/g, "'")
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

function extractJavaScriptVar(html, name) {
  const prefix = `var ${name} = `;
  const varIndex = html.indexOf(prefix);

  if (varIndex === -1) return null;

  const start = varIndex + prefix.length;
  let depth = 0;
  let inString = false;
  let quote = "";
  let escaping = false;

  for (let index = start; index < html.length; index += 1) {
    const char = html[index];

    if (inString) {
      if (escaping) {
        escaping = false;
      } else if (char === "\\") {
        escaping = true;
      } else if (char === quote) {
        inString = false;
      }
      continue;
    }

    if (char === "\"" || char === "'") {
      inString = true;
      quote = char;
    } else if (char === "[" || char === "{") {
      depth += 1;
    } else if (char === "]" || char === "}") {
      depth -= 1;
    } else if (char === ";" && depth === 0) {
      return html.slice(start, index);
    }
  }

  return null;
}

function addToIndex(index, key, row) {
  if (!key) return;

  if (!index.has(key)) index.set(key, []);
  index.get(key).push(row);
}

function findUniqueIndexMatch(index, key) {
  const matches = index.get(key) ?? [];
  return matches.length === 1 ? matches[0] : null;
}

function extractAddedPatch(html) {
  const match = html.match(
    /Added in patch\s+\[acronym=\\?"([0-9]+(?:\.[0-9]+){1,3})[^"\\]*\\?"\]([0-9]+(?:\.[0-9]+){1,2})\[\\?\/acronym\]/,
  );

  if (match) return match[2];

  const looseMatch = html.match(/Added in patch[\s\S]{0,160}?([0-9]+(?:\.[0-9]+){1,2})/);
  return looseMatch?.[1] ?? null;
}

function extractWowheadItemId(finalUrl) {
  const match = String(finalUrl ?? "").match(/\/item=(\d+)/);
  return match ? Number(match[1]) : null;
}

async function fetchPatch(kind, id) {
  const url = categoryUrls[kind](id);
  const response = await axios.get(url, {
    headers: {
      "User-Agent": "Mozilla/5.0 WoW100 patch audit",
    },
    maxRedirects: 8,
    responseType: "text",
    timeout: 20000,
  });
  const patch = extractAddedPatch(response.data);
  const finalUrl = response.request?.res?.responseUrl ?? url;

  return {
    url,
    finalUrl,
    patch,
    patchExpansion: patchToExpansion(patch),
    wowheadItemId: kind === "mount" ? extractWowheadItemId(finalUrl) : null,
    fetchedAt: new Date().toISOString(),
  };
}

async function fetchWowheadMountItemRows() {
  const rows = [];

  for (const expansion of mountItemExpansionFilters) {
    const url = `https://www.wowhead.com/fr/items/miscellaneous/mounts?filter=166;${expansion.wowheadId};0`;
    const response = await axios.get(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 WoW100 patch audit",
      },
      responseType: "text",
      timeout: 20000,
    });
    const listviewItems = extractJavaScriptVar(response.data, "listviewitems");
    const expansionRows = listviewItems ? Function(`return (${listviewItems});`)() : [];

    for (const row of expansionRows) {
      rows.push({
        ...row,
        wowheadExpansion: expansion.key,
      });
    }

    console.log(`${expansion.key}: ${expansionRows.length} objets de monture Wowhead`);
  }

  return rows;
}

function buildMountItemIndexes(rows) {
  const exact = new Map();
  const stripped = new Map();

  for (const row of rows) {
    const normalized = normalizeName(row.name);
    addToIndex(exact, normalized, row);
    addToIndex(stripped, withoutAcquisitionPrefix(normalized), row);
  }

  return { exact, stripped };
}

function findMountItemMatch(mount, indexes) {
  const normalized = normalizeName(mount.name);
  const exact = findUniqueIndexMatch(indexes.exact, normalized);

  if (exact) return { row: exact, matchType: "exactName" };

  const stripped = findUniqueIndexMatch(indexes.stripped, normalized);

  if (stripped) return { row: stripped, matchType: "strippedAcquisitionPrefix" };

  return null;
}

function mountItemPatchData(item, match) {
  const patch = match.row.firstseenpatch ?? null;

  return {
    url: `https://www.wowhead.com/fr/item=${match.row.id}`,
    finalUrl: `https://www.wowhead.com/fr/item=${match.row.id}`,
    patch,
    patchExpansion: patch && patch !== 0 ? patchToExpansion(patch) : match.row.wowheadExpansion,
    wowheadItemId: match.row.id,
    sourceExpansion: match.row.wowheadExpansion,
    matchSource: "wowhead_mount_item_list",
    matchType: match.matchType,
    fetchedAt: new Date().toISOString(),
  };
}

async function loadCurrentMounts() {
  const catalog = await loadJson(sourceFiles.mountsCatalog, []);
  const manualById = byBlizzardId(await loadJson(sourceFiles.mountManualMetadata, []));
  const overridesById = byBlizzardId(await loadJson(sourceFiles.mountWowheadOverrides, []));
  const draftById = byBlizzardId(await loadJson(sourceFiles.mountMamytwinkDraft, []));
  const candidatesById = byBlizzardId(
    (await loadJson(sourceFiles.mountMamytwinkCandidates, { candidates: [] })).candidates ?? [],
  );

  return catalog.map((mount) => {
    const id = mount.id;
    const override = overridesById.get(id);
    const manual = manualById.get(id);
    const draft = draftById.get(id);
    const candidate = candidatesById.get(id);
    const expansion = firstNonEmpty(
      override?.expansion,
      manual?.expansion,
      draft?.expansion,
      candidate?.expansion,
    );

    return {
      kind: "mount",
      blizzardId: id,
      name: mount.name,
      currentExpansion: normalizeExpansion(expansion),
      currentSource: firstNonEmpty(
        override?.source,
        override?.sourceName,
        manual?.source,
        manual?.sourceName,
        candidate?.source,
        mount.sourceName,
        mount.sourceType,
      ),
      hasAvailabilityOverride: Boolean(override),
    };
  });
}

async function loadDraftItems(kind, filePath) {
  const rows = await loadJson(filePath, []);

  return rows
    .filter((row) => Number.isInteger(row.blizzardId))
    .map((row) => ({
      kind,
      blizzardId: row.blizzardId,
      name: row.name,
      currentExpansion: normalizeExpansion(row.expansion),
      currentSource: firstNonEmpty(row.source, row.sourceName, row.instance),
      hasAvailabilityOverride: false,
    }));
}

function classify(item, patchData) {
  const patchExpansion = patchData?.sourceExpansion ?? patchData?.patchExpansion ?? null;
  const currentExpansion = item.currentExpansion ?? null;

  if (patchData?.error) return "fetch_failed";
  if (!patchExpansion && (patchData?.patch == null || patchData.patch === "")) {
    return "patch_missing";
  }
  if (!currentExpansion) return "unclassified";
  if (currentExpansion === patchExpansion) return "ok";
  if (item.hasAvailabilityOverride) return "availability_override";

  return "mismatch";
}

async function saveJson(filePath, value) {
  await fs.writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

async function saveCache(cache) {
  await saveJson(cachePath, cache);
}

async function main() {
  await fs.mkdir(generatedDir, { recursive: true });

  const cache = await loadJson(cachePath, {
    generatedAt: null,
    entries: {},
  });
  cache.entries ??= {};

  const allItems = [
    ...(selectedKinds.has("mount") ? await loadCurrentMounts() : []),
    ...(selectedKinds.has("pet") ? await loadDraftItems("pet", sourceFiles.petsDraft) : []),
    ...(selectedKinds.has("achievement")
      ? await loadDraftItems("achievement", sourceFiles.achievementsDraft)
      : []),
  ];
  const items = maxPages > 0 ? allItems.slice(0, maxPages) : allItems;
  const mountItemIndexes = selectedKinds.has("mount") && !offline
    ? buildMountItemIndexes(await fetchWowheadMountItemRows())
    : null;
  let nextIndex = 0;
  let completed = 0;

  async function worker() {
    while (nextIndex < items.length) {
      const index = nextIndex;
      nextIndex += 1;
      const item = items[index];
      const key = `${item.kind}:${item.blizzardId}`;
      const mountItemMatch =
        item.kind === "mount" && mountItemIndexes
          ? findMountItemMatch(item, mountItemIndexes)
          : null;

      if (mountItemMatch) {
        cache.entries[key] = mountItemPatchData(item, mountItemMatch);
        completed += 1;

        if (completed % 100 === 0 || completed === items.length) {
          console.log(`${completed}/${items.length} pages/listes Wowhead auditees`);
          await saveCache(cache);
        }
        continue;
      }

      if (!refresh && cache.entries[key]?.patch !== undefined) {
        completed += 1;
        continue;
      }

      if (offline) {
        completed += 1;
        continue;
      }

      try {
        cache.entries[key] = await fetchPatch(item.kind, item.blizzardId);
      } catch (error) {
        cache.entries[key] = {
          url: categoryUrls[item.kind](item.blizzardId),
          error: error?.response?.status
            ? `HTTP ${error.response.status}`
            : error.message,
          fetchedAt: new Date().toISOString(),
        };
      }

      completed += 1;

      if (completed % 100 === 0 || completed === items.length) {
        console.log(`${completed}/${items.length} pages/listes Wowhead auditees`);
        await saveCache(cache);
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));

  cache.generatedAt = new Date().toISOString();
  await saveCache(cache);

  const rows = items.map((item) => {
    const patchData = cache.entries[`${item.kind}:${item.blizzardId}`] ?? {};
    const patchExpansion = patchData.sourceExpansion ?? patchData.patchExpansion ?? null;
    const status = classify(item, patchData);

    return {
      status,
      kind: item.kind,
      blizzardId: item.blizzardId,
      name: item.name,
      currentExpansion: item.currentExpansion,
      patch: patchData.patch ?? null,
      patchExpansion,
      currentSource: item.currentSource,
      hasAvailabilityOverride: item.hasAvailabilityOverride,
      wowheadUrl: patchData.finalUrl ?? patchData.url ?? categoryUrls[item.kind](item.blizzardId),
      wowheadItemId: patchData.wowheadItemId ?? null,
      matchSource: patchData.matchSource ?? "wowhead_page",
      matchType: patchData.matchType ?? null,
      error: patchData.error ?? null,
    };
  });

  const byStatus = {};
  const byKind = {};

  for (const row of rows) {
    byStatus[row.status] = (byStatus[row.status] ?? 0) + 1;
    byKind[row.kind] ??= {};
    byKind[row.kind][row.status] = (byKind[row.kind][row.status] ?? 0) + 1;
  }

  const report = {
    generatedAt: new Date().toISOString(),
    source:
      "Wowhead page infobox Added in patch, or filtered Wowhead mount item expansion when page patch is unavailable",
    selectedKinds: [...selectedKinds],
    audited: rows.length,
    byStatus,
    byKind,
    mismatches: rows.filter((row) => row.status === "mismatch"),
    unclassifiedWithPatch: rows.filter((row) => row.status === "unclassified"),
    availabilityOverrides: rows.filter((row) => row.status === "availability_override"),
    patchMissing: rows.filter((row) => row.status === "patch_missing"),
    fetchFailed: rows.filter((row) => row.status === "fetch_failed"),
  };

  await saveJson(reportPath, report);

  console.log(
    JSON.stringify(
      {
        reportPath: path.relative(repoRoot, reportPath),
        cachePath: path.relative(repoRoot, cachePath),
        audited: report.audited,
        byStatus,
        byKind,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
