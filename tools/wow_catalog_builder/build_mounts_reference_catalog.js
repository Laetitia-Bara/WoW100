import axios from "axios";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
const generatedDir = path.join(repoRoot, "assets/generated");
const metadataDir = path.join(repoRoot, "assets/data/metadata");

const paths = {
  blizzardCatalog: path.join(generatedDir, "mounts_catalog_enriched.json"),
  mamytwinkCandidates: path.join(generatedDir, "mamytwink_mount_candidates.json"),
  mamytwinkDetailCache: path.join(
    generatedDir,
    "mamytwink_mount_detail_cache.json",
  ),
  manualMetadata: path.join(metadataDir, "mounts_metadata.json"),
  locationOverrides: path.join(metadataDir, "mount_location_overrides.json"),
  wowheadOverrides: path.join(metadataDir, "mounts_wowhead_overrides.json"),
  wowheadPatchCache: path.join(generatedDir, "wowhead_patch_audit_cache.json"),
  zonesCatalog: path.join(generatedDir, "zones_wowhead_catalog.json"),
  referenceCatalog: path.join(generatedDir, "mounts_reference_catalog.json"),
  auditReport: path.join(generatedDir, "mounts_reference_audit_report.json"),
  ambiguousReviewJson: path.join(
    generatedDir,
    "mount_location_ambiguous_review.json",
  ),
  ambiguousReviewCsv: path.join(
    generatedDir,
    "mount_location_ambiguous_review.csv",
  ),
};

const TBD = "à définir";

function decodeHtml(value) {
  return String(value ?? "")
    .replace(/&nbsp;/g, " ")
    .replace(/&#039;/g, "'")
    .replace(/&#x27;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) =>
      String.fromCodePoint(Number.parseInt(code, 16)),
    );
}

function stripTags(value) {
  return decodeHtml(String(value ?? "").replace(/<[^>]+>/g, " "))
    .replace(/\s+/g, " ")
    .trim();
}

function normalize(value) {
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

function parseMamytwinkDetail(html, url) {
  const title = stripTags(html.match(/<title>([\s\S]*?)<\/title>/)?.[1] ?? "");
  const canonical =
    html.match(/<link rel="canonical" href="([^"]+)"/)?.[1] ?? url;
  const description = decodeHtml(
    html.match(/<meta name="description" content="([^"]*)"/)?.[1] ?? "",
  ).trim();
  const keywordsHtml =
    html.match(/<p>\s*<strong>Mots clés<\/strong>\s*:\s*([\s\S]*?)<\/p>/)
      ?.[1] ?? "";
  const keywords = stripTags(keywordsHtml)
    .split(",")
    .map((keyword) => keyword.trim())
    .filter(Boolean);
  const tagsStart = html.indexOf('class="tags_monture"');
  const tagsEnd = tagsStart === -1 ? -1 : html.indexOf("<h1", tagsStart);
  const tagsHtml =
    tagsStart === -1 || tagsEnd === -1 ? "" : html.slice(tagsStart, tagsEnd);
  const patch =
    stripTags(tagsHtml).match(/Patch\s+([0-9]+(?:\.[0-9]+){1,2})/i)?.[1] ??
    null;
  const source =
    stripTags(
      html.match(/<strong>\s*Source\s*:\s*<\/strong>\s*([\s\S]*?)<\/div>/i)
        ?.[1] ?? "",
    ) || null;
  const difficulty =
    stripTags(
      html.match(/Difficulté d'obtention\s*:\s*([^"]+)"/i)?.[1] ?? "",
    ) ||
    stripTags(
      html.match(/Difficulté d’obtention\s*:\s*([^"]+)"/i)?.[1] ?? "",
    ) ||
    null;
  const plainText = stripTags(
    html.match(/<div class="description-monture">([\s\S]*?)<\/div>/)?.[1] ??
      "",
  );

  return {
    url: canonical,
    title,
    description,
    keywords,
    patch,
    source,
    difficulty,
    detailText: plainText,
  };
}

async function fetchMamytwinkDetails(candidates, cache) {
  const byUrl = new Map(
    Object.entries(cache.details ?? {}).map(([url, detail]) => [url, detail]),
  );
  const urls = [
    ...new Set(
      candidates
        .map((candidate) => candidate.mamytwinkUrl)
        .filter((url) => typeof url === "string" && url.startsWith("https://")),
    ),
  ];
  const missing = urls.filter((url) => !byUrl.has(url));
  let cursor = 0;
  let fetched = 0;
  const concurrency = 5;

  async function worker() {
    while (cursor < missing.length) {
      const url = missing[cursor];
      cursor += 1;

      try {
        const response = await axios.get(url, {
          headers: {
            "User-Agent": "WoW100 metadata helper (+manual verification)",
          },
          responseType: "text",
          timeout: 20000,
        });
        byUrl.set(url, {
          ...parseMamytwinkDetail(response.data, url),
          fetchedAt: new Date().toISOString(),
        });
      } catch (error) {
        byUrl.set(url, {
          url,
          error: error?.response?.status ?? error.message,
          fetchedAt: new Date().toISOString(),
        });
      }

      fetched += 1;
      if (fetched % 100 === 0) {
        console.log(`${fetched}/${missing.length} fiches Mamytwink recuperees`);
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));

  const nextCache = {
    generatedAt: new Date().toISOString(),
    source: "https://www.mamytwink.com/montures",
    details: Object.fromEntries([...byUrl.entries()].sort()),
  };

  await fs.writeFile(
    paths.mamytwinkDetailCache,
    `${JSON.stringify(nextCache, null, 2)}\n`,
    "utf8",
  );

  return byUrl;
}

function buildZoneIndex(zonesCatalog) {
  const entries = [];

  for (const zone of zonesCatalog.zones ?? []) {
    if (!zone.name || !zone.geographicRegionName) continue;
    entries.push({
      id: zone.id,
      name: zone.name,
      key: normalize(zone.name),
      regionName: zone.geographicRegionName,
      expansionKey: zone.expansionKey,
      instanceTypeName: zone.instanceTypeName,
    });
  }

  return entries;
}

function findLocationCandidates(detail, zoneIndex) {
  const keywordKeys = new Set((detail?.keywords ?? []).map(normalize));
  const candidates = [];

  for (const zone of zoneIndex) {
    if (!keywordKeys.has(zone.key)) continue;
    candidates.push({
      zoneId: zone.id,
      zoneName: zone.name,
      regionName: zone.regionName,
      expansionKey: zone.expansionKey,
      matchSource: "mamytwink_keywords",
    });
  }

  return candidates;
}

function wowheadUrlFor(mount, wowheadOverride, wowheadCacheEntry) {
  const itemId = wowheadOverride?.wowheadItemId ?? wowheadCacheEntry?.wowheadItemId;
  if (Number.isInteger(itemId)) {
    return {
      url: `https://www.wowhead.com/fr/item=${itemId}`,
      type: "item",
      itemId,
    };
  }

  return {
    url: `https://www.wowhead.com/fr/mount/${mount.id}`,
    type: "mount_fallback",
    itemId: null,
  };
}

function cleanSource(value) {
  const source = firstNonEmpty(value);
  if (!source) return "";

  return source
    .replace(/\s+/g, " ")
    .trim()
    .replace(/^Source\s*:\s*/i, "");
}

function buildReferenceMount({
  mount,
  mamytwinkCandidate,
  mamytwinkDetail,
  wowheadOverride,
  wowheadCacheEntry,
  manualMetadata,
  locationOverride,
  zoneIndex,
}) {
  const sourceFromWowhead = cleanSource(
    wowheadOverride?.source ?? wowheadOverride?.sourceName,
  );
  const sourceFromMamytwink = cleanSource(
    mamytwinkDetail?.source ?? mamytwinkCandidate?.source,
  );
  const difficultyFromMamytwink = firstNonEmpty(
    mamytwinkDetail?.difficulty,
    mamytwinkCandidate?.difficulty,
  );
  const expansionFromMamytwink = firstNonEmpty(mamytwinkCandidate?.expansion);
  const patchFromMamytwink = firstNonEmpty(mamytwinkDetail?.patch);
  const mamytwinkUrl = firstNonEmpty(
    mamytwinkDetail?.url,
    mamytwinkCandidate?.mamytwinkUrl,
  );
  const locationCandidates = findLocationCandidates(mamytwinkDetail, zoneIndex);
  const uniqueLocation =
    locationCandidates.length === 1 ? locationCandidates[0] : null;
  const manualLocation = locationOverride
    ? zoneIndex.find((zone) => zone.id === locationOverride.zoneId)
    : null;
  if (locationOverride && !manualLocation) {
    throw new Error(
      `Zone ${locationOverride.zoneId} introuvable pour la monture ${mount.id}`,
    );
  }
  const selectedLocation = manualLocation ?? uniqueLocation;
  const wowheadLink = wowheadUrlFor(mount, wowheadOverride, wowheadCacheEntry);
  const missingFields = [];
  const fieldSources = {
    difficulty: difficultyFromMamytwink ? "mamytwink" : "manual_required",
    source: sourceFromWowhead
      ? "wowhead_override"
      : sourceFromMamytwink
        ? "mamytwink"
        : "manual_required",
    expansion: expansionFromMamytwink ? "mamytwink" : "manual_required",
    patch: patchFromMamytwink ? "mamytwink_detail" : "manual_required",
    mamytwinkUrl: mamytwinkUrl ? "mamytwink" : "manual_required",
    wowheadUrl:
      wowheadOverride?.externalUrl || wowheadCacheEntry
        ? "wowhead"
        : "wowhead_mount_fallback",
    locationCandidates: locationCandidates.length
      ? "mamytwink_keywords"
      : "manual_required",
    zone: manualLocation
      ? "manual_override"
      : uniqueLocation
        ? "mamytwink_keywords_unique_match"
        : "manual_required",
    continent: manualLocation
      ? "wowhead_zone_catalog_via_manual_override"
      : uniqueLocation
        ? "wowhead_zone_catalog"
        : "manual_required",
  };
  const values = {
    difficulty: difficultyFromMamytwink || TBD,
    source: sourceFromWowhead || sourceFromMamytwink || TBD,
    expansion: expansionFromMamytwink || TBD,
    patch: patchFromMamytwink || TBD,
    mamytwinkUrl: mamytwinkUrl || "",
    wowheadUrl: wowheadLink.url,
  };

  for (const [key, value] of Object.entries(values)) {
    if (!value || value === TBD) missingFields.push(key);
  }
  if (!selectedLocation) {
    missingFields.push(
      locationCandidates.length ? "locationDecision" : "locationCandidates",
    );
  }
  if (wowheadLink.type !== "item") missingFields.push("wowheadItemUrl");

  return {
    blizzardId: mount.id,
    name: mount.name,
    description: mount.description ?? "",
    officialSourceType: mount.sourceType || "UNKNOWN",
    officialSourceName: mount.sourceName || "",
    faction: mount.faction || "",
    requirements: mount.requirements ?? null,
    source: values.source,
    acquisitionCategory:
      wowheadOverride?.category ?? manualMetadata?.category ?? mamytwinkCandidate?.source ?? TBD,
    difficulty: values.difficulty,
    expansion: values.expansion,
    patch: values.patch,
    mamytwinkUrl: values.mamytwinkUrl,
    wowheadUrl: values.wowheadUrl,
    wowheadUrlType: wowheadLink.type,
    wowheadItemId: wowheadLink.itemId,
    links: [
      {
        provider: "mamytwink",
        label: "M",
        iconHint: "green_m",
        url: values.mamytwinkUrl,
        primary: true,
      },
      {
        provider: "wowhead",
        label: "WH",
        iconHint: "wowhead_rocket",
        url: values.wowheadUrl,
        primary: false,
      },
    ].filter((link) => link.url),
    locationCandidates,
    locationAssignment: selectedLocation
      ? manualLocation
        ? {
            status: "manually_assigned",
            zoneId: manualLocation.id,
            zoneName: manualLocation.name,
            continentName: manualLocation.regionName,
            source: "manual_override_and_wowhead_zone_catalog",
            note: locationOverride.note ?? "",
          }
        : {
            status: "auto_assigned_unique_candidate",
            zoneId: uniqueLocation.zoneId,
            zoneName: uniqueLocation.zoneName,
            continentName: uniqueLocation.regionName,
            source: "mamytwink_keywords_and_wowhead_zone_catalog",
          }
      : {
          status: locationCandidates.length
            ? "manual_choice_required"
            : "no_candidate",
          zoneId: null,
          zoneName: TBD,
          continentName: TBD,
          source: "manual_required",
        },
    zoneId: selectedLocation?.zoneId ?? selectedLocation?.id ?? null,
    zone: selectedLocation?.zoneName ?? selectedLocation?.name ?? TBD,
    continent:
      selectedLocation?.regionName ?? TBD,
    instance: manualMetadata?.instance ?? wowheadOverride?.instance ?? TBD,
    boss: manualMetadata?.boss ?? wowheadOverride?.boss ?? "",
    groupRequired:
      wowheadOverride?.groupRequired ?? manualMetadata?.groupRequired ?? false,
    weeklyLockout:
      wowheadOverride?.weeklyLockout ??
      manualMetadata?.weeklyLockout ??
      mount.sourceType === "DROP",
    mamytwink: mamytwinkCandidate
      ? {
          name: mamytwinkCandidate.mamytwinkName,
          type: mamytwinkCandidate.type,
          difficulty: mamytwinkCandidate.difficulty,
          source: mamytwinkCandidate.source,
          expansion: mamytwinkCandidate.expansion,
          url: mamytwinkCandidate.mamytwinkUrl,
          matchType: mamytwinkCandidate.matchType,
          confidence: mamytwinkCandidate.confidence,
          keywords: mamytwinkDetail?.keywords ?? [],
          detailPatch: mamytwinkDetail?.patch ?? null,
        }
      : null,
    wowhead: {
      override: wowheadOverride ?? null,
      cache: wowheadCacheEntry
        ? {
            patch: wowheadCacheEntry.patch ?? null,
            patchExpansion: wowheadCacheEntry.patchExpansion ?? null,
            matchSource: wowheadCacheEntry.matchSource ?? null,
            matchType: wowheadCacheEntry.matchType ?? null,
          }
        : null,
    },
    fieldSources,
    missingFields,
  };
}

function countBy(rows, selector) {
  return rows.reduce((acc, row) => {
    const key = selector(row);
    acc[key] = (acc[key] ?? 0) + 1;
    return acc;
  }, {});
}

function uniqueJoined(values) {
  return [...new Set(values.filter(Boolean))].join(" | ");
}

function buildAmbiguousReview(referenceMounts) {
  return referenceMounts
    .filter(
      (mount) => mount.locationAssignment.status === "manual_choice_required",
    )
    .map((mount) => ({
      blizzardId: mount.blizzardId,
      monture: mount.name,
      extensionMonture: mount.expansion,
      patch: mount.patch,
      source: mount.source,
      difficulty: mount.difficulty,
      motsClesMamytwink: (mount.mamytwink?.keywords ?? []).join(" | "),
      nombreCandidates: mount.locationCandidates.length,
      zonesCandidates: uniqueJoined(
        mount.locationCandidates.map((candidate) => candidate.zoneName),
      ),
      regionsCandidates: uniqueJoined(
        mount.locationCandidates.map((candidate) => candidate.regionName),
      ),
      zoneIdsCandidates: uniqueJoined(
        mount.locationCandidates.map((candidate) => String(candidate.zoneId)),
      ),
      extensionsCandidates: uniqueJoined(
        mount.locationCandidates.map((candidate) => candidate.expansionKey),
      ),
      statutRevue: "Plusieurs candidates - choix manuel",
      mamytwinkUrl: mount.mamytwinkUrl,
      wowheadUrl: mount.wowheadUrl,
      decisionManuelle: "",
      zoneIdRetenue: "",
      notes: "",
    }));
}

function toSemicolonCsv(rows) {
  if (!rows.length) return "";
  const headers = Object.keys(rows[0]);
  const escape = (value) => `"${String(value ?? "").replace(/"/g, '""')}"`;
  return [
    headers.map(escape).join(";"),
    ...rows.map((row) => headers.map((header) => escape(row[header])).join(";")),
  ].join("\n");
}

async function writeReviewCsv(content) {
  try {
    await fs.writeFile(paths.ambiguousReviewCsv, content, "utf8");
  } catch (error) {
    if (error.code !== "EBUSY") throw error;

    const fallbackPath = path.join(
      generatedDir,
      "mount_location_ambiguous_review_updated.csv",
    );
    await fs.writeFile(fallbackPath, content, "utf8");
    console.warn(
      `CSV de revue ouvert : copie actualisee ecrite dans ${fallbackPath}`,
    );
  }
}

function buildAudit(referenceMounts, candidates, cache) {
  const missingByField = {};
  for (const mount of referenceMounts) {
    for (const field of mount.missingFields) {
      missingByField[field] = (missingByField[field] ?? 0) + 1;
    }
  }

  return {
    total: referenceMounts.length,
    mamytwinkCandidates: candidates.length,
    mamytwinkDetailPagesCached: Object.keys(cache.details ?? {}).length,
    missingByField,
    byDifficulty: countBy(referenceMounts, (mount) => mount.difficulty),
    bySource: countBy(referenceMounts, (mount) => mount.source),
    byExpansion: countBy(referenceMounts, (mount) => mount.expansion),
    byPatch: countBy(referenceMounts, (mount) => mount.patch),
    locationCandidateCount: referenceMounts.filter(
      (mount) => mount.locationCandidates.length,
    ).length,
    locationsAutoAssigned: referenceMounts.filter(
      (mount) =>
        mount.locationAssignment.status === "auto_assigned_unique_candidate",
    ).length,
    locationsManuallyAssigned: referenceMounts.filter(
      (mount) => mount.locationAssignment.status === "manually_assigned",
    ).length,
    locationsRequiringManualChoice: referenceMounts.filter(
      (mount) => mount.locationAssignment.status === "manual_choice_required",
    ).length,
    locationsWithoutCandidate: referenceMounts.filter(
      (mount) => mount.locationAssignment.status === "no_candidate",
    ).length,
    note:
      "Les correspondances exactes avec une candidate unique sont affectees automatiquement. Les correspondances multiples restent reservees a la revue manuelle.",
  };
}

async function main() {
  const [
    blizzardCatalog,
    mamytwinkData,
    mamytwinkDetailCache,
    manualMetadata,
    locationOverrides,
    wowheadOverrides,
    wowheadPatchCache,
    zonesCatalog,
  ] = await Promise.all([
    loadJson(paths.blizzardCatalog, []),
    loadJson(paths.mamytwinkCandidates, { candidates: [] }),
    loadJson(paths.mamytwinkDetailCache, { details: {} }),
    loadJson(paths.manualMetadata, []),
    loadJson(paths.locationOverrides, []),
    loadJson(paths.wowheadOverrides, []),
    loadJson(paths.wowheadPatchCache, { entries: {} }),
    loadJson(paths.zonesCatalog, { zones: [] }),
  ]);

  const mamytwinkCandidates = mamytwinkData.candidates ?? [];
  const mamytwinkById = byBlizzardId(mamytwinkCandidates);
  const manualById = byBlizzardId(manualMetadata);
  const locationOverrideById = byBlizzardId(locationOverrides);
  const wowheadById = byBlizzardId(wowheadOverrides);
  const mamytwinkDetailsByUrl = await fetchMamytwinkDetails(
    mamytwinkCandidates,
    mamytwinkDetailCache,
  );
  const freshDetailCache = await loadJson(paths.mamytwinkDetailCache, {
    details: {},
  });
  const zoneIndex = buildZoneIndex(zonesCatalog);

  const referenceMounts = blizzardCatalog
    .map((mount) => {
      const mamytwinkCandidate = mamytwinkById.get(mount.id);
      return buildReferenceMount({
        mount,
        mamytwinkCandidate,
        mamytwinkDetail: mamytwinkDetailsByUrl.get(
          mamytwinkCandidate?.mamytwinkUrl,
        ),
        wowheadOverride: wowheadById.get(mount.id),
        wowheadCacheEntry: wowheadPatchCache.entries?.[`mount:${mount.id}`],
        manualMetadata: manualById.get(mount.id),
        locationOverride: locationOverrideById.get(mount.id),
        zoneIndex,
      });
    })
    .sort((a, b) => a.blizzardId - b.blizzardId);

  const audit = buildAudit(
    referenceMounts,
    mamytwinkCandidates,
    freshDetailCache,
  );
  const output = {
    source: {
      blizzard: "https://eu.api.blizzard.com/data/wow/mount/index",
      mamytwink: "https://www.mamytwink.com/montures",
      wowhead: "https://www.wowhead.com/fr/mount-collection-tracker",
    },
    rules: {
      difficulty: "Mamytwink, sinon à définir",
      source: "Wowhead override/cache, puis Mamytwink, sinon à définir",
      expansion: "Mamytwink, sinon à définir",
      patch: "Fiche detail Mamytwink, sinon à définir",
      links: "Mamytwink en lien principal et Wowhead FR en lien secondaire",
    },
    mounts: referenceMounts,
  };
  const ambiguousReview = buildAmbiguousReview(referenceMounts);

  await Promise.all([
    fs.writeFile(
      paths.referenceCatalog,
      `${JSON.stringify(output, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.auditReport,
      `${JSON.stringify(audit, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.ambiguousReviewJson,
      `${JSON.stringify(
        { total: ambiguousReview.length, rows: ambiguousReview },
        null,
        2,
      )}\n`,
      "utf8",
    ),
    writeReviewCsv(`${toSemicolonCsv(ambiguousReview)}\n`),
  ]);

  console.log(
    [
      `${referenceMounts.length} montures referencees`,
      `${audit.mamytwinkCandidates} correspondances Mamytwink`,
      `${audit.mamytwinkDetailPagesCached} fiches detail Mamytwink en cache`,
      `${audit.locationCandidateCount} candidates de localisation`,
    ].join(" | "),
  );
  console.log(JSON.stringify(audit.missingByField, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
