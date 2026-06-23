import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
const generatedDir = path.join(repoRoot, "assets/generated");
const metadataDir = path.join(repoRoot, "assets/data/metadata");

const paths = {
  wowheadCatalog: path.join(generatedDir, "zones_wowhead_catalog.json"),
  overrides: path.join(metadataDir, "location_reference_overrides.json"),
  easternKingdomsManualReview: path.join(
    metadataDir,
    "location_eastern_kingdoms_manual_review.json",
  ),
  northrendManualReview: path.join(
    metadataDir,
    "location_northrend_manual_review.json",
  ),
  pandariaManualReview: path.join(
    metadataDir,
    "location_pandaria_manual_review.json",
  ),
  draenorManualReview: path.join(
    metadataDir,
    "location_draenor_manual_review.json",
  ),
  brokenIslesManualReview: path.join(
    metadataDir,
    "location_broken_isles_manual_review.json",
  ),
  zandalarManualReview: path.join(
    metadataDir,
    "location_zandalar_manual_review.json",
  ),
  kulTirasManualReview: path.join(
    metadataDir,
    "location_kul_tiras_manual_review.json",
  ),
  shadowlandsManualReview: path.join(
    metadataDir,
    "location_shadowlands_manual_review.json",
  ),
  dragonIslesManualReview: path.join(
    metadataDir,
    "location_dragon_isles_manual_review.json",
  ),
  khazAlgarManualReview: path.join(
    metadataDir,
    "location_khaz_algar_manual_review.json",
  ),
  quelThalasManualReview: path.join(
    metadataDir,
    "location_quel_thalas_manual_review.json",
  ),
  output: path.join(generatedDir, "locations_reference_catalog.json"),
  audit: path.join(generatedDir, "locations_reference_audit_report.json"),
  kalimdorReview: path.join(generatedDir, "locations_kalimdor_review.json"),
  kalimdorReviewCsv: path.join(
    generatedDir,
    "locations_kalimdor_review.csv",
  ),
  easternKingdomsReview: path.join(
    generatedDir,
    "locations_eastern_kingdoms_review.json",
  ),
  easternKingdomsCatalogCsv: path.join(
    generatedDir,
    "locations_eastern_kingdoms_catalog.csv",
  ),
  outlandReview: path.join(generatedDir, "locations_outland_review.json"),
  outlandReviewCsv: path.join(
    generatedDir,
    "locations_outland_review.csv",
  ),
  northrendReview: path.join(
    generatedDir,
    "locations_northrend_review.json",
  ),
  northrendCatalogCsv: path.join(
    generatedDir,
    "locations_northrend_catalog.csv",
  ),
  maelstromReview: path.join(
    generatedDir,
    "locations_maelstrom_review.json",
  ),
  maelstromReviewCsv: path.join(
    generatedDir,
    "locations_maelstrom_review.csv",
  ),
  pandariaReview: path.join(
    generatedDir,
    "locations_pandaria_review.json",
  ),
  pandariaReviewCsv: path.join(
    generatedDir,
    "locations_pandaria_review.csv",
  ),
  draenorReview: path.join(
    generatedDir,
    "locations_draenor_review.json",
  ),
  draenorReviewCsv: path.join(
    generatedDir,
    "locations_draenor_review.csv",
  ),
  brokenIslesReview: path.join(
    generatedDir,
    "locations_broken_isles_review.json",
  ),
  brokenIslesReviewCsv: path.join(
    generatedDir,
    "locations_broken_isles_review.csv",
  ),
  zandalarReview: path.join(
    generatedDir,
    "locations_zandalar_review.json",
  ),
  zandalarReviewCsv: path.join(
    generatedDir,
    "locations_zandalar_review.csv",
  ),
  kulTirasReview: path.join(
    generatedDir,
    "locations_kul_tiras_review.json",
  ),
  kulTirasReviewCsv: path.join(
    generatedDir,
    "locations_kul_tiras_review.csv",
  ),
  shadowlandsReview: path.join(
    generatedDir,
    "locations_shadowlands_review.json",
  ),
  shadowlandsReviewCsv: path.join(
    generatedDir,
    "locations_shadowlands_review.csv",
  ),
  dragonIslesReview: path.join(
    generatedDir,
    "locations_dragon_isles_review.json",
  ),
  dragonIslesReviewCsv: path.join(
    generatedDir,
    "locations_dragon_isles_review.csv",
  ),
  khazAlgarReview: path.join(
    generatedDir,
    "locations_khaz_algar_review.json",
  ),
  khazAlgarReviewCsv: path.join(
    generatedDir,
    "locations_khaz_algar_review.csv",
  ),
  quelThalasReview: path.join(
    generatedDir,
    "locations_quel_thalas_review.json",
  ),
  quelThalasReviewCsv: path.join(
    generatedDir,
    "locations_quel_thalas_review.csv",
  ),
};

async function loadJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

function byKey(rows, keySelector) {
  return new Map(rows.map((row) => [keySelector(row), row]));
}

function countBy(rows, selector) {
  return rows.reduce((counts, row) => {
    const key = selector(row) ?? "null";
    counts[key] = (counts[key] ?? 0) + 1;
    return counts;
  }, {});
}

function sourceRef(zoneId) {
  return `wowhead-zone:${zoneId}`;
}

function buildBaseLocation(zone, continent) {
  return {
    ref: sourceRef(zone.id),
    wowheadZoneId: zone.id,
    name: zone.name,
    normalizedName: zone.normalizedName,
    worldKey: continent.worldKey,
    continentKey: continent.key,
    kind: "region",
    parentRef: `continent:${continent.key}`,
    parentRefs: [`continent:${continent.key}`],
    depthBelowContinent: 1,
    regionRef: sourceRef(zone.id),
    regionName: zone.name,
    extensionId: zone.expansionId,
    extensionKey: zone.expansionKey,
    extensionName: zone.expansionName,
    expansionBasePatch: zone.expansionBasePatch,
    patch: zone.patch,
    instanceTypeId: zone.instanceTypeId,
    instanceTypeName: zone.instanceTypeName,
    territoryId: zone.territoryId,
    territoryName: zone.territoryName,
    minLevel: zone.minLevel,
    maxLevel: zone.maxLevel,
    wowheadUrl: zone.wowheadUrl,
    reviewStatus: "pending",
    reviewMethod: null,
    reviewBatch: null,
    note: "",
    source: "wowhead_zone_catalog",
  };
}

function applyRule(location, rule, continentsByKey) {
  if (rule.continentKey) {
    const continent = continentsByKey.get(rule.continentKey);
    if (!continent) {
      throw new Error(`Continent inconnu dans une règle: ${rule.continentKey}`);
    }
    location.continentKey = continent.key;
    location.worldKey = continent.worldKey;
  }
  for (const field of [
    "kind",
    "parentRef",
    "extensionId",
    "extensionKey",
    "extensionName",
    "instanceTypeName",
    "regionRefOverride",
    "regionNameOverride",
    "reviewRegionName",
    "reviewStatus",
    "note",
  ]) {
    if (rule[field] !== undefined) location[field] = rule[field];
  }
  location.source = "wowhead_zone_catalog_and_manual_review";
  location.parentRefs = [location.parentRef];
  if (rule.reviewStatus === "reviewed") {
    location.reviewMethod = "user_manual_rule";
  } else if (rule.reviewStatus === "pending") {
    location.reviewMethod = "awaiting_manual_review";
  }
}

function resolveHierarchy(locations, continentsByKey) {
  const locationsByRef = byKey(locations, (location) => location.ref);
  const visiting = new Set();
  const resolved = new Set();

  function resolve(location) {
    if (resolved.has(location.ref)) return;
    if (visiting.has(location.ref)) {
      throw new Error(`Cycle de localisation détecté: ${location.ref}`);
    }
    visiting.add(location.ref);

    if (location.parentRef.startsWith("continent:")) {
      const continentKey = location.parentRef.slice("continent:".length);
      const continent = continentsByKey.get(continentKey);
      if (!continent) {
        throw new Error(`Parent continent introuvable: ${location.parentRef}`);
      }
      location.worldKey = continent.worldKey;
      location.continentKey = continent.key;
      location.depthBelowContinent = 1;
      if (location.kind === "region") {
        location.regionRef = location.ref;
        location.regionName = location.name;
      } else {
        location.regionRef = location.regionRefOverride ?? null;
        location.regionName = location.regionNameOverride ?? null;
      }
    } else {
      const parent = locationsByRef.get(location.parentRef);
      if (!parent) {
        throw new Error(
          `Parent de localisation introuvable pour ${location.ref}: ${location.parentRef}`,
        );
      }
      resolve(parent);
      location.worldKey = parent.worldKey;
      location.continentKey = parent.continentKey;
      location.depthBelowContinent = parent.depthBelowContinent + 1;
      if (location.kind === "region") {
        location.regionRef = location.ref;
        location.regionName = location.name;
      } else {
        location.regionRef =
          parent.kind === "region" ? parent.ref : parent.regionRef;
        location.regionName =
          parent.kind === "region" ? parent.name : parent.regionName;
      }
    }

    visiting.delete(location.ref);
    delete location.regionRefOverride;
    delete location.regionNameOverride;
    resolved.add(location.ref);
  }

  for (const location of locations) resolve(location);
  for (const location of locations) {
    for (const parentRef of location.parentRefs ?? [location.parentRef]) {
      if (parentRef.startsWith("continent:")) {
        const continentKey = parentRef.slice("continent:".length);
        if (!continentsByKey.has(continentKey)) {
          throw new Error(`Parent continent introuvable: ${parentRef}`);
        }
      } else if (!locationsByRef.has(parentRef)) {
        throw new Error(
          `Parent secondaire introuvable pour ${location.ref}: ${parentRef}`,
        );
      }
    }
  }
}

function buildContinentPath(continent, continentsByKey) {
  const names = [];
  const visited = new Set();
  let cursor = continent;
  while (cursor) {
    if (visited.has(cursor.key)) {
      throw new Error(`Cycle de continents détecté: ${cursor.key}`);
    }
    visited.add(cursor.key);
    names.unshift(cursor.name);
    if (!cursor.parentContinentKey) break;
    cursor = continentsByKey.get(cursor.parentContinentKey);
    if (!cursor) {
      throw new Error(
        `Continent parent introuvable: ${continent.parentContinentKey}`,
      );
    }
  }
  return names;
}

function buildPath(location, locationsByRef, worldsByKey, continentsByKey) {
  const world = worldsByKey.get(location.worldKey);
  const continent = continentsByKey.get(location.continentKey);
  const continentNames = buildContinentPath(continent, continentsByKey);
  const locationNames = [];
  let cursor = location;

  while (cursor) {
    locationNames.unshift(cursor.name);
    if (cursor.parentRef.startsWith("continent:")) break;
    cursor = locationsByRef.get(cursor.parentRef);
  }

  return [world?.name, ...continentNames, ...locationNames].filter(Boolean);
}

function attachCanonicalReferences(locations) {
  const groupsByPath = new Map();

  for (const location of locations) {
    const key = normalizeLookupName(location.pathLabel);
    const group = groupsByPath.get(key) ?? [];
    group.push(location);
    groupsByPath.set(key, group);
  }

  const aliases = [];
  for (const group of groupsByPath.values()) {
    const ordered = [...group].sort((left, right) => {
      const leftManual = left.ref.startsWith("manual-location:") ? 0 : 1;
      const rightManual = right.ref.startsWith("manual-location:") ? 0 : 1;
      if (leftManual !== rightManual) return leftManual - rightManual;

      const leftReviewed = left.reviewStatus === "reviewed" ? 0 : 1;
      const rightReviewed = right.reviewStatus === "reviewed" ? 0 : 1;
      if (leftReviewed !== rightReviewed) return leftReviewed - rightReviewed;

      const leftId = left.wowheadZoneId ?? Number.MAX_SAFE_INTEGER;
      const rightId = right.wowheadZoneId ?? Number.MAX_SAFE_INTEGER;
      return leftId - rightId || left.ref.localeCompare(right.ref, "fr");
    });
    const canonical = ordered[0];
    const aliasRefs = ordered.map((location) => location.ref);
    const wowheadZoneIds = ordered
      .map((location) => location.wowheadZoneId)
      .filter(Number.isInteger);

    for (const location of group) {
      location.canonicalRef = canonical.ref;
      location.isCanonical = location.ref === canonical.ref;
      location.aliasRefs = aliasRefs;
      location.canonicalWowheadZoneIds = wowheadZoneIds;
    }

    if (group.length > 1) {
      aliases.push({
        canonicalRef: canonical.ref,
        pathLabel: canonical.pathLabel,
        aliasRefs,
        wowheadZoneIds,
      });
    }
  }

  const canonicalByRef = new Map(
    locations.map((location) => [location.ref, location.canonicalRef]),
  );
  for (const location of locations) {
    location.canonicalParentRef = location.parentRef.startsWith("continent:")
      ? location.parentRef
      : canonicalByRef.get(location.parentRef) ?? location.parentRef;
    location.canonicalParentRefs = (location.parentRefs ?? [location.parentRef]).map(
      (parentRef) =>
        parentRef.startsWith("continent:")
          ? parentRef
          : canonicalByRef.get(parentRef) ?? parentRef,
    );
    location.canonicalRegionRef =
      canonicalByRef.get(location.regionRef) ?? location.regionRef;
  }

  return aliases.sort((left, right) =>
    left.pathLabel.localeCompare(right.pathLabel, "fr"),
  );
}

function csvCell(value) {
  return `"${String(value ?? "").replace(/"/g, '""')}"`;
}

function toSemicolonCsv(rows) {
  if (!rows.length) return "";
  const headers = Object.keys(rows[0]);
  return `\uFEFF${[
    headers.map(csvCell).join(";"),
    ...rows.map((row) =>
      headers.map((header) => csvCell(row[header])).join(";"),
    ),
  ].join("\n")}`;
}

function findNameExclusionRule(locationName, continentKey, rules) {
  const normalizedName = locationName.toLocaleLowerCase("fr-FR");
  return (rules ?? []).find((rule) => {
    if (rule.continentKey !== continentKey) return false;
    if (rule.matchMode === "contains_case_insensitive") {
      return normalizedName.includes(
        String(rule.match).toLocaleLowerCase("fr-FR"),
      );
    }
    if (rule.matchMode === "contains_any_case_insensitive") {
      return (rule.matches ?? []).some((match) =>
        normalizedName.includes(String(match).toLocaleLowerCase("fr-FR")),
      );
    }
    return false;
  });
}

function normalizeLookupName(value) {
  return String(value ?? "")
    .toLocaleLowerCase("fr-FR")
    .replace(/[’`]/g, "'")
    .replace(/\u00a0/g, " ")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function slugify(value) {
  return normalizeLookupName(value)
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function reviewDecisionIsDeleted(value) {
  return normalizeLookupName(value).startsWith("supprim");
}

function buildExpansionLookup(zones) {
  const lookup = new Map();
  for (const zone of zones) {
    lookup.set(normalizeLookupName(zone.expansionName), {
      extensionId: zone.expansionId,
      extensionKey: zone.expansionKey,
      extensionName: zone.expansionName,
      expansionBasePatch: zone.expansionBasePatch,
    });
  }
  const burningCrusade = lookup.get("the burning crusade");
  if (burningCrusade) {
    lookup.set("the burning crusafe", burningCrusade);
  }
  return lookup;
}

function chooseParentCandidate(candidates, childExtensionId) {
  return [...candidates].sort((a, b) => {
    const aSame = a.expansion.extensionId === childExtensionId ? 1 : 0;
    const bSame = b.expansion.extensionId === childExtensionId ? 1 : 0;
    if (aSame !== bSame) return bSame - aSame;

    const aBefore = a.expansion.extensionId <= childExtensionId ? 1 : 0;
    const bBefore = b.expansion.extensionId <= childExtensionId ? 1 : 0;
    if (aBefore !== bBefore) return bBefore - aBefore;
    if (aBefore && bBefore) {
      return b.expansion.extensionId - a.expansion.extensionId;
    }
    return (
      Math.abs(a.expansion.extensionId - childExtensionId) -
        Math.abs(b.expansion.extensionId - childExtensionId) ||
      a.wowheadZoneId - b.wowheadZoneId
    );
  })[0];
}

function prepareManualReview({
  manualReview,
  sourceZones,
  continent,
  expansionLookup,
  capitalZoneIds = [],
}) {
  const reviewBatch =
    manualReview.reviewBatch ?? "eastern-kingdoms-manual-review";
  const sourceById = byKey(sourceZones, (zone) => zone.id);
  const capitalZoneIdSet = new Set(capitalZoneIds);
  const decisions = [];
  const keptRows = [];

  for (const row of manualReview.rows ?? []) {
    const sourceZone = sourceById.get(row.wowheadZoneId);
    if (!sourceZone) {
      throw new Error(
        `Zone ${row.wowheadZoneId} de la revue manuelle introuvable`,
      );
    }
    if (sourceZone.wowheadCategoryId !== continent.wowheadCategoryId) {
      throw new Error(
        `Zone ${row.wowheadZoneId} hors du continent ${continent.key}`,
      );
    }

    if (reviewDecisionIsDeleted(row.decision)) {
      decisions.push({
        wowheadZoneId: row.wowheadZoneId,
        action: "exclude",
        name: row.name,
        reason: row.note || "Décision Supprimée lors de la revue manuelle.",
      });
      continue;
    }

    const expansion =
      expansionLookup.get(normalizeLookupName(row.extensionName)) ?? {
        extensionId: sourceZone.expansionId,
        extensionKey: sourceZone.expansionKey,
        extensionName: sourceZone.expansionName,
        expansionBasePatch: sourceZone.expansionBasePatch,
      };
    const prepared = {
      wowheadZoneId: row.wowheadZoneId,
      name: row.name,
      regionName: row.regionName || row.name,
      extensionNameFromReview: row.extensionName,
      instanceTypeName: row.instanceTypeName || sourceZone.instanceTypeName,
      note: row.note || "",
      expansion,
    };
    keptRows.push(prepared);
  }

  const directRegionsByName = new Map();
  for (const row of keptRows) {
    if (
      normalizeLookupName(row.name) !== normalizeLookupName(row.regionName) &&
      !capitalZoneIdSet.has(row.wowheadZoneId)
    ) {
      continue;
    }
    const key = normalizeLookupName(row.name);
    const candidates = directRegionsByName.get(key) ?? [];
    candidates.push(row);
    directRegionsByName.set(key, candidates);
  }

  const syntheticByName = new Map();
  function syntheticParent(parentName, child) {
    const key = normalizeLookupName(parentName);
    let synthetic = syntheticByName.get(key);
    if (!synthetic) {
      const ref = `manual-location:${continent.key}:${slugify(parentName)}`;
      synthetic = {
        ref,
        wowheadZoneId: null,
        name: parentName,
        normalizedName: slugify(parentName),
        worldKey: continent.worldKey,
        continentKey: continent.key,
        kind: "region",
        parentRef: `continent:${continent.key}`,
        parentRefs: [`continent:${continent.key}`],
        depthBelowContinent: 1,
        regionRef: ref,
        regionName: parentName,
        extensionId: child.expansion.extensionId,
        extensionKey: child.expansion.extensionKey,
        extensionName: child.expansion.extensionName,
        expansionBasePatch: child.expansion.expansionBasePatch,
        patch: null,
        instanceTypeId: null,
        instanceTypeName: "Zone",
        territoryId: null,
        territoryName: "Inconnu",
        minLevel: null,
        maxLevel: null,
        wowheadUrl: "",
        reviewStatus: "reviewed",
        reviewMethod: "user_manual_review_synthetic_parent",
        reviewBatch,
        note: "Région parente créée depuis la revue manuelle.",
        source: "user_manual_review",
      };
      syntheticByName.set(key, synthetic);
    }
    return synthetic;
  }

  for (const row of keptRows) {
    const sameRegion =
      normalizeLookupName(row.name) === normalizeLookupName(row.regionName);
    const isCapital = capitalZoneIdSet.has(row.wowheadZoneId);
    if (sameRegion) {
      decisions.push({
        ...row,
        reviewBatch,
        action: "keep",
        kind: "region",
        parentRef: `continent:${continent.key}`,
        parentRefs: [`continent:${continent.key}`],
      });
      continue;
    }

    let parentNames = [row.regionName];
    if (!directRegionsByName.has(normalizeLookupName(row.regionName))) {
      const splitNames = row.regionName
        .split(",")
        .map((name) => name.trim())
        .filter(Boolean);
      if (splitNames.length > 1) parentNames = splitNames;
    }
    if (isCapital) {
      parentNames = parentNames.filter(
        (parentName) =>
          normalizeLookupName(parentName) !== normalizeLookupName(row.name),
      );
    }

    const parentRefs = parentNames.map((parentName) => {
      const candidates =
        directRegionsByName.get(normalizeLookupName(parentName)) ?? [];
      if (candidates.length) {
        return sourceRef(
          chooseParentCandidate(
            candidates,
            row.expansion.extensionId,
          ).wowheadZoneId,
        );
      }
      return syntheticParent(parentName, row).ref;
    });

    decisions.push({
      ...row,
      reviewBatch,
      action: "keep",
      kind: isCapital ? "region" : "subzone",
      parentRef: parentRefs[0] ?? `continent:${continent.key}`,
      parentRefs: parentRefs.length
        ? parentRefs
        : [`continent:${continent.key}`],
    });
  }

  return {
    decisionsByZoneId: byKey(decisions, (decision) => decision.wowheadZoneId),
    syntheticLocations: [...syntheticByName.values()],
    sourceRowCount: manualReview.rows?.length ?? 0,
  };
}

function applyManualReviewDecision(location, decision) {
  location.name = decision.name;
  location.normalizedName = slugify(decision.name);
  location.kind = decision.kind;
  location.parentRef = decision.parentRef;
  location.parentRefs = decision.parentRefs;
  location.reviewRegionName = decision.regionName;
  location.extensionId = decision.expansion.extensionId;
  location.extensionKey = decision.expansion.extensionKey;
  location.extensionName = decision.expansion.extensionName;
  location.expansionBasePatch = decision.expansion.expansionBasePatch;
  location.instanceTypeName = decision.instanceTypeName;
  location.reviewStatus = "reviewed";
  location.reviewMethod = "user_manual_review";
  location.reviewBatch = decision.reviewBatch;
  location.note = decision.note;
  location.source = "wowhead_zone_catalog_and_user_manual_review";
}

function buildReviewRows({
  locations,
  exclusions,
  worldsByKey,
  continentsByKey,
}) {
  return [
    ...locations.map((location) => ({
      wowheadZoneId: location.wowheadZoneId,
      nom: location.name,
      decision: "Conservée",
      monde: worldsByKey.get(location.worldKey)?.name ?? location.worldKey,
      continent:
        continentsByKey.get(location.continentKey)?.name ??
        location.continentKey,
      region: location.reviewRegionName ?? location.regionName ?? "",
      parent: (location.parentRefs ?? [location.parentRef]).join(" | "),
      typeGeographique: location.kind,
      profondeur: location.depthBelowContinent,
      extension: location.extensionName,
      typeInstance: location.instanceTypeName,
      statutRevue: location.reviewStatus,
      methodeRevue: location.reviewMethod ?? "",
      chemin: location.pathLabel,
      note: location.note,
      wowheadUrl: location.wowheadUrl,
    })),
    ...exclusions.map((exclusion) => ({
      wowheadZoneId: exclusion.wowheadZoneId,
      nom: exclusion.name,
      decision: "Supprimée",
      monde: exclusion.worldName,
      continent: exclusion.continentName,
      region: "",
      parent: "",
      typeGeographique: "",
      profondeur: "",
      extension: exclusion.expansionName,
      typeInstance: exclusion.instanceTypeName ?? "",
      statutRevue: "excluded",
      methodeRevue: exclusion.exclusionMethod,
      chemin: "",
      note: exclusion.reason,
      wowheadUrl: `https://www.wowhead.com/fr/zone=${exclusion.wowheadZoneId}`,
    })),
  ].sort((a, b) =>
    `${a.decision}|${a.chemin}|${a.nom}`.localeCompare(
      `${b.decision}|${b.chemin}|${b.nom}`,
      "fr",
    ),
  );
}

async function main() {
  const [
    wowheadCatalog,
    config,
    easternKingdomsManualReview,
    northrendManualReview,
    pandariaManualReview,
    draenorManualReview,
    brokenIslesManualReview,
    zandalarManualReview,
    kulTirasManualReview,
    shadowlandsManualReview,
    dragonIslesManualReview,
    khazAlgarManualReview,
    quelThalasManualReview,
  ] = await Promise.all([
      loadJson(paths.wowheadCatalog),
      loadJson(paths.overrides),
      loadJson(paths.easternKingdomsManualReview),
      loadJson(paths.northrendManualReview),
      loadJson(paths.pandariaManualReview),
      loadJson(paths.draenorManualReview),
      loadJson(paths.brokenIslesManualReview),
      loadJson(paths.zandalarManualReview),
      loadJson(paths.kulTirasManualReview),
      loadJson(paths.shadowlandsManualReview),
      loadJson(paths.dragonIslesManualReview),
      loadJson(paths.khazAlgarManualReview),
      loadJson(paths.quelThalasManualReview),
    ]);
  const worldsByKey = byKey(config.worlds, (world) => world.key);
  const continentsByKey = byKey(
    config.continents,
    (continent) => continent.key,
  );
  const continentsByWowheadCategoryId = byKey(
    config.continents,
    (continent) => continent.wowheadCategoryId,
  );
  const rulesByZoneId = byKey(config.rules, (rule) => rule.wowheadZoneId);
  const batchesByContinent = byKey(
    config.reviewBatches,
    (batch) => batch.continentKey,
  );
  const expansionLookup = buildExpansionLookup(wowheadCatalog.zones ?? []);
  const easternKingdomsContinent = continentsByKey.get("eastern-kingdoms");
  const easternKingdomsBatch = batchesByContinent.get("eastern-kingdoms");
  const easternKingdomsManual = prepareManualReview({
    manualReview: easternKingdomsManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: easternKingdomsContinent,
    expansionLookup,
    capitalZoneIds: easternKingdomsBatch?.capitalZoneIds ?? [],
  });
  const northrendContinent = continentsByKey.get("northrend");
  const northrendBatch = batchesByContinent.get("northrend");
  const northrendManual = prepareManualReview({
    manualReview: northrendManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: northrendContinent,
    expansionLookup,
    capitalZoneIds: northrendBatch?.capitalZoneIds ?? [],
  });
  const pandariaContinent = continentsByKey.get("pandaria");
  const pandariaBatch = batchesByContinent.get("pandaria");
  const pandariaManual = prepareManualReview({
    manualReview: pandariaManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: pandariaContinent,
    expansionLookup,
    capitalZoneIds: pandariaBatch?.capitalZoneIds ?? [],
  });
  const draenorContinent = continentsByKey.get("draenor");
  const draenorBatch = batchesByContinent.get("draenor");
  const draenorManual = prepareManualReview({
    manualReview: draenorManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: draenorContinent,
    expansionLookup,
    capitalZoneIds: draenorBatch?.capitalZoneIds ?? [],
  });
  const brokenIslesContinent = continentsByKey.get("broken-isles");
  const brokenIslesBatch = batchesByContinent.get("broken-isles");
  const brokenIslesManual = prepareManualReview({
    manualReview: brokenIslesManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: brokenIslesContinent,
    expansionLookup,
    capitalZoneIds: brokenIslesBatch?.capitalZoneIds ?? [],
  });
  const zandalarContinent = continentsByKey.get("zandalar");
  const zandalarBatch = batchesByContinent.get("zandalar");
  const zandalarManual = prepareManualReview({
    manualReview: zandalarManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: zandalarContinent,
    expansionLookup,
    capitalZoneIds: zandalarBatch?.capitalZoneIds ?? [],
  });
  const kulTirasContinent = continentsByKey.get("kul-tiras");
  const kulTirasBatch = batchesByContinent.get("kul-tiras");
  const kulTirasManual = prepareManualReview({
    manualReview: kulTirasManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: kulTirasContinent,
    expansionLookup,
    capitalZoneIds: kulTirasBatch?.capitalZoneIds ?? [],
  });
  const shadowlandsContinent = continentsByKey.get("shadowlands");
  const shadowlandsBatch = batchesByContinent.get("shadowlands");
  const shadowlandsManual = prepareManualReview({
    manualReview: shadowlandsManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: shadowlandsContinent,
    expansionLookup,
    capitalZoneIds: shadowlandsBatch?.capitalZoneIds ?? [],
  });
  const dragonIslesContinent = continentsByKey.get("dragon-isles");
  const dragonIslesBatch = batchesByContinent.get("dragon-isles");
  const dragonIslesManual = prepareManualReview({
    manualReview: dragonIslesManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: dragonIslesContinent,
    expansionLookup,
    capitalZoneIds: dragonIslesBatch?.capitalZoneIds ?? [],
  });
  const khazAlgarContinent = continentsByKey.get("khaz-algar");
  const khazAlgarBatch = batchesByContinent.get("khaz-algar");
  const khazAlgarManual = prepareManualReview({
    manualReview: khazAlgarManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: khazAlgarContinent,
    expansionLookup,
    capitalZoneIds: khazAlgarBatch?.capitalZoneIds ?? [],
  });
  const quelThalasContinent = continentsByKey.get("quel-thalas");
  const quelThalasBatch = batchesByContinent.get("quel-thalas");
  const quelThalasManual = prepareManualReview({
    manualReview: quelThalasManualReview,
    sourceZones: wowheadCatalog.zones ?? [],
    continent: quelThalasContinent,
    expansionLookup,
    capitalZoneIds: quelThalasBatch?.capitalZoneIds ?? [],
  });
  const manualReviewsByContinent = new Map([
    ["eastern-kingdoms", easternKingdomsManual],
    ["northrend", northrendManual],
    ["pandaria", pandariaManual],
    ["draenor", draenorManual],
    ["broken-isles", brokenIslesManual],
    ["zandalar", zandalarManual],
    ["kul-tiras", kulTirasManual],
    ["shadowlands", shadowlandsManual],
    ["dragon-isles", dragonIslesManual],
    ["khaz-algar", khazAlgarManual],
    ["quel-thalas", quelThalasManual],
  ]);

  for (const continent of config.continents) {
    if (!worldsByKey.has(continent.worldKey)) {
      throw new Error(
        `Monde ${continent.worldKey} introuvable pour ${continent.key}`,
      );
    }
    if (continent.parentContinentKey) {
      const parentContinent = continentsByKey.get(
        continent.parentContinentKey,
      );
      if (!parentContinent) {
        throw new Error(
          `Continent parent ${continent.parentContinentKey} introuvable pour ${continent.key}`,
        );
      }
      if (parentContinent.worldKey !== continent.worldKey) {
        throw new Error(
          `Les continents ${continent.key} et ${parentContinent.key} ne partagent pas le même monde`,
        );
      }
      buildContinentPath(continent, continentsByKey);
    }
  }

  const exclusions = [];
  const unassignedSourceEntries = [];
  const locations = [];

  for (const zone of wowheadCatalog.zones ?? []) {
    const rule = rulesByZoneId.get(zone.id);
    const continent = rule?.continentKey
      ? continentsByKey.get(rule.continentKey)
      : continentsByWowheadCategoryId.get(zone.wowheadCategoryId);
    if (!continent) {
      unassignedSourceEntries.push({
        wowheadZoneId: zone.id,
        name: zone.name,
        wowheadCategoryId: zone.wowheadCategoryId,
        wowheadCategoryName: zone.wowheadCategoryName,
        instanceTypeName: zone.instanceTypeName,
        expansionName: zone.expansionName,
        wowheadUrl: zone.wowheadUrl,
        reviewStatus: "pending_geographic_assignment",
      });
      continue;
    }

    const manualDecision = manualReviewsByContinent
      .get(continent.key)
      ?.decisionsByZoneId.get(zone.id);
    const nameExclusionRule = findNameExclusionRule(
      zone.name,
      continent.key,
      config.nameExclusionRules,
    );
    if (
      manualDecision?.action === "exclude" ||
      (!manualDecision && (rule?.action === "exclude" || nameExclusionRule))
    ) {
      const exclusionRule = manualDecision ??
        (rule?.action === "exclude" ? rule : nameExclusionRule);
      exclusions.push({
        wowheadZoneId: zone.id,
        name: manualDecision?.name ?? zone.name,
        worldKey: continent.worldKey,
        worldName: worldsByKey.get(continent.worldKey)?.name ?? continent.worldKey,
        continentKey: continent.key,
        continentName: continent.name,
        expansionName: manualDecision?.extensionNameFromReview ?? zone.expansionName,
        instanceTypeName:
          manualDecision?.instanceTypeName ?? zone.instanceTypeName,
        exclusionMethod: manualDecision
          ? "user_manual_review"
          : nameExclusionRule?.key ?? "user_manual_rule",
        reason: exclusionRule.reason,
      });
      continue;
    }

    const location = buildBaseLocation(zone, continent);
    const batch = batchesByContinent.get(continent.key);
    if (manualDecision?.action === "keep") {
      applyManualReviewDecision(location, manualDecision);
    } else if (
      batch &&
      !batch.excludedDefaultZoneIds.includes(zone.id)
    ) {
      location.kind = batch.defaultKind ?? location.kind;
      location.reviewStatus = batch.defaultReviewStatus ?? "pending";
      location.reviewMethod =
        location.reviewStatus === "reviewed"
          ? "user_default_region"
          : "awaiting_manual_review";
      location.reviewBatch = batch.key;
      location.source = "wowhead_zone_catalog_and_user_review";
    }
    if (!manualDecision && rule?.action === "override") {
      applyRule(location, rule, continentsByKey);
      location.reviewBatch = batch?.key ?? "manual-rule";
    }
    locations.push(location);
  }

  locations.push(...easternKingdomsManual.syntheticLocations);
  locations.push(...northrendManual.syntheticLocations);
  locations.push(...pandariaManual.syntheticLocations);
  locations.push(...draenorManual.syntheticLocations);
  locations.push(...brokenIslesManual.syntheticLocations);
  locations.push(...zandalarManual.syntheticLocations);
  locations.push(...kulTirasManual.syntheticLocations);
  locations.push(...shadowlandsManual.syntheticLocations);
  locations.push(...dragonIslesManual.syntheticLocations);
  locations.push(...khazAlgarManual.syntheticLocations);
  locations.push(...quelThalasManual.syntheticLocations);

  resolveHierarchy(locations, continentsByKey);
  const locationsByRef = byKey(locations, (location) => location.ref);
  for (const location of locations) {
    location.path = buildPath(
      location,
      locationsByRef,
      worldsByKey,
      continentsByKey,
    );
    location.pathLabel = location.path.join(" > ");
  }
  const canonicalAliases = attachCanonicalReferences(locations);

  locations.sort((a, b) =>
    `${a.worldKey}|${a.continentKey}|${a.pathLabel}|${a.wowheadZoneId}`.localeCompare(
      `${b.worldKey}|${b.continentKey}|${b.pathLabel}|${b.wowheadZoneId}`,
      "fr",
    ),
  );
  exclusions.sort((a, b) => a.wowheadZoneId - b.wowheadZoneId);

  const kalimdorLocations = locations.filter(
    (location) =>
      location.continentKey === "kalimdor" ||
      location.wowheadZoneId === 8093,
  );
  const kalimdorExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "kalimdor",
  );
  const kalimdorReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 1,
    ).length,
    suppliedListEntries: 43,
    retainedEntries: kalimdorLocations.length,
    retainedUnderKalimdor: kalimdorLocations.filter(
      (location) => location.continentKey === "kalimdor",
    ).length,
    movedToAnotherContinent: kalimdorLocations.filter(
      (location) => location.continentKey !== "kalimdor",
    ).length,
    excludedEntries: kalimdorExclusions.length,
    reviewedEntries: kalimdorLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: kalimdorLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(kalimdorLocations, (location) => location.kind),
    locations: kalimdorLocations,
    exclusions: kalimdorExclusions,
  };
  const kalimdorReviewRows = buildReviewRows({
    locations: kalimdorLocations,
    exclusions: kalimdorExclusions,
    worldsByKey,
    continentsByKey,
  });
  const easternKingdomsLocations = locations.filter(
    (location) => location.continentKey === "eastern-kingdoms",
  );
  const easternKingdomsSourceLocations = easternKingdomsLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const easternKingdomsSyntheticLocations = easternKingdomsLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const easternKingdomsExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "eastern-kingdoms",
  );
  const easternKingdomsReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 0,
    ).length,
    suppliedListEntries: 259,
    retainedEntries: easternKingdomsSourceLocations.length,
    canonicalLocationNodes: easternKingdomsLocations.length,
    syntheticRegions: easternKingdomsSyntheticLocations.length,
    subzones: easternKingdomsSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    multiParentLocations: easternKingdomsSourceLocations.filter(
      (location) => (location.parentRefs?.length ?? 1) > 1,
    ).length,
    excludedEntries: easternKingdomsExclusions.length,
    excludedByTestRule: easternKingdomsExclusions.filter(
      (exclusion) => exclusion.exclusionMethod === "name_contains_test",
    ).length,
    excludedByDoNotDisturbRule: easternKingdomsExclusions.filter(
      (exclusion) =>
        exclusion.exclusionMethod === "name_contains_do_not_disturb" ||
        exclusion.exclusionMethod.startsWith(
          "name_contains_ne_pas_deranger",
        ),
    ).length,
    excludedByTechnicalMarkerRule: easternKingdomsExclusions.filter(
      (exclusion) =>
        exclusion.exclusionMethod === "name_contains_technical_marker",
    ).length,
    reviewedEntries: easternKingdomsLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: easternKingdomsLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(
      easternKingdomsLocations,
      (location) => location.kind,
    ),
    locations: easternKingdomsLocations,
    exclusions: easternKingdomsExclusions,
  };
  const easternKingdomsReviewRows = buildReviewRows({
    locations: easternKingdomsLocations,
    exclusions: easternKingdomsExclusions,
    worldsByKey,
    continentsByKey,
  });
  const outlandLocations = locations.filter(
    (location) => location.continentKey === "outland",
  );
  const outlandExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "outland",
  );
  const outlandReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 8,
    ).length,
    suppliedListEntries: 7,
    retainedEntries: outlandLocations.length,
    displayedRegions: outlandLocations.filter(
      (location) => location.wowheadZoneId !== 3703,
    ).length,
    capitalRegions: outlandLocations.filter(
      (location) => location.wowheadZoneId === 3703,
    ).length,
    excludedEntries: outlandExclusions.length,
    reviewedEntries: outlandLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: outlandLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(outlandLocations, (location) => location.kind),
    locations: outlandLocations,
    exclusions: outlandExclusions,
  };
  const outlandReviewRows = buildReviewRows({
    locations: outlandLocations,
    exclusions: outlandExclusions,
    worldsByKey,
    continentsByKey,
  });
  const northrendLocations = locations.filter(
    (location) => location.continentKey === "northrend",
  );
  const northrendExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "northrend",
  );
  const northrendCapitalIds = new Set([4395, 8474]);
  const northrendReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 10,
    ).length,
    suppliedListEntries: 18,
    retainedEntries: northrendLocations.length,
    syntheticRegions: northrendManual.syntheticLocations.length,
    subzones: northrendLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    displayedRegions: northrendLocations.filter(
      (location) => location.wowheadZoneId !== 4395,
    ).length,
    capitalCandidates: northrendLocations.filter((location) =>
      northrendCapitalIds.has(location.wowheadZoneId),
    ).length,
    capitalOutsideDisplayedList: northrendLocations.filter(
      (location) => location.wowheadZoneId === 4395,
    ).length,
    deletedCapitalCandidates: northrendExclusions.filter(
      (exclusion) => exclusion.wowheadZoneId === 4395,
    ).length,
    excludedEntries: northrendExclusions.length,
    reviewedEntries: northrendLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: northrendLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(northrendLocations, (location) => location.kind),
    locations: northrendLocations,
    exclusions: northrendExclusions,
  };
  const northrendReviewRows = buildReviewRows({
    locations: northrendLocations,
    exclusions: northrendExclusions,
    worldsByKey,
    continentsByKey,
  });
  const maelstromLocations = locations.filter(
    (location) => location.continentKey === "maelstrom",
  );
  const maelstromExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "maelstrom",
  );
  const maelstromReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 11,
    ).length,
    suppliedListEntries: 8,
    retainedSourceRegions: maelstromLocations.filter(
      (location) =>
        location.wowheadZoneId !== 8093 && location.kind === "region",
    ).length,
    importedSubzones: maelstromLocations.filter(
      (location) => location.wowheadZoneId === 8093,
    ).length,
    canonicalLocationNodes: maelstromLocations.length,
    capitalRegions: 0,
    excludedEntries: maelstromExclusions.length,
    reviewedEntries: maelstromLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: maelstromLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(maelstromLocations, (location) => location.kind),
    locations: maelstromLocations,
    exclusions: maelstromExclusions,
  };
  const maelstromReviewRows = buildReviewRows({
    locations: maelstromLocations,
    exclusions: maelstromExclusions,
    worldsByKey,
    continentsByKey,
  });
  const pandariaUnlistedZoneIds = new Set([6142]);
  const pandariaLocations = locations.filter(
    (location) =>
      location.continentKey === "pandaria" &&
      !pandariaUnlistedZoneIds.has(location.wowheadZoneId),
  );
  const pandariaSourceLocations = pandariaLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const pandariaSyntheticLocations = pandariaLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const pandariaExclusions = exclusions.filter(
    (exclusion) =>
      exclusion.continentKey === "pandaria" &&
      !pandariaUnlistedZoneIds.has(exclusion.wowheadZoneId),
  );
  const pandariaReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 12,
    ).length,
    suppliedListEntries: 46,
    unlistedEntries: pandariaUnlistedZoneIds.size,
    unlistedZoneIds: [...pandariaUnlistedZoneIds],
    retainedEntries: pandariaSourceLocations.length,
    canonicalLocationNodes: pandariaLocations.length,
    syntheticRegions: pandariaSyntheticLocations.length,
    subzones: pandariaSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    excludedEntries: pandariaExclusions.length,
    reviewedEntries: pandariaLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: pandariaLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(pandariaLocations, (location) => location.kind),
    locations: pandariaLocations,
    exclusions: pandariaExclusions,
  };
  const pandariaReviewRows = buildReviewRows({
    locations: pandariaSourceLocations,
    exclusions: pandariaExclusions,
    worldsByKey,
    continentsByKey,
  });
  const draenorUnlistedZoneIds = new Set([7332, 7333]);
  const draenorLocations = locations.filter(
    (location) =>
      location.continentKey === "draenor" &&
      !draenorUnlistedZoneIds.has(location.wowheadZoneId),
  );
  const draenorSourceLocations = draenorLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const draenorSyntheticLocations = draenorLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const draenorExclusions = exclusions.filter(
    (exclusion) =>
      exclusion.continentKey === "draenor" &&
      !draenorUnlistedZoneIds.has(exclusion.wowheadZoneId),
  );
  const draenorReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 13,
    ).length,
    suppliedListEntries: 13,
    unlistedEntries: draenorUnlistedZoneIds.size,
    unlistedZoneIds: [...draenorUnlistedZoneIds],
    retainedEntries: draenorSourceLocations.length,
    canonicalLocationNodes: draenorLocations.length,
    syntheticRegions: draenorSyntheticLocations.length,
    subzones: draenorSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    excludedEntries: draenorExclusions.length,
    reviewedEntries: draenorLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: draenorLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(draenorLocations, (location) => location.kind),
    locations: draenorLocations,
    exclusions: draenorExclusions,
  };
  const draenorReviewRows = buildReviewRows({
    locations: draenorSourceLocations,
    exclusions: draenorExclusions,
    worldsByKey,
    continentsByKey,
  });
  const brokenIslesUnlistedZoneIds = new Set([7502]);
  const brokenIslesLocations = locations.filter(
    (location) =>
      location.continentKey === "broken-isles" &&
      !brokenIslesUnlistedZoneIds.has(location.wowheadZoneId),
  );
  const brokenIslesSourceLocations = brokenIslesLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const brokenIslesSyntheticLocations = brokenIslesLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const brokenIslesExclusions = exclusions.filter(
    (exclusion) =>
      exclusion.continentKey === "broken-isles" &&
      !brokenIslesUnlistedZoneIds.has(exclusion.wowheadZoneId),
  );
  const brokenIslesReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 14,
    ).length,
    suppliedListEntries: 54,
    unlistedEntries: brokenIslesUnlistedZoneIds.size,
    unlistedZoneIds: [...brokenIslesUnlistedZoneIds],
    retainedEntries: brokenIslesSourceLocations.length,
    canonicalLocationNodes: brokenIslesLocations.length,
    syntheticRegions: brokenIslesSyntheticLocations.length,
    subzones: brokenIslesSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    excludedEntries: brokenIslesExclusions.length,
    reviewedEntries: brokenIslesLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: brokenIslesLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(brokenIslesLocations, (location) => location.kind),
    locations: brokenIslesLocations,
    exclusions: brokenIslesExclusions,
  };
  const brokenIslesReviewRows = buildReviewRows({
    locations: brokenIslesSourceLocations,
    exclusions: brokenIslesExclusions,
    worldsByKey,
    continentsByKey,
  });
  const zandalarCapitalZoneIds = new Set([8670]);
  const zandalarLocations = locations.filter(
    (location) => location.continentKey === "zandalar",
  );
  const zandalarSourceLocations = zandalarLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const zandalarSyntheticLocations = zandalarLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const zandalarExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "zandalar",
  );
  const zandalarReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 15,
    ).length,
    suppliedListEntries: 29,
    retainedEntries: zandalarSourceLocations.length,
    canonicalLocationNodes: zandalarLocations.length,
    syntheticRegions: zandalarSyntheticLocations.length,
    subzones: zandalarSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    displayedEntries: zandalarSourceLocations.filter(
      (location) => !zandalarCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalCandidates: zandalarLocations.filter((location) =>
      zandalarCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalOutsideDisplayedList: zandalarLocations.filter(
      (location) => location.wowheadZoneId === 8670,
    ).length,
    excludedEntries: zandalarExclusions.length,
    reviewedEntries: zandalarLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: zandalarLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(zandalarLocations, (location) => location.kind),
    locations: zandalarLocations,
    exclusions: zandalarExclusions,
  };
  const zandalarReviewRows = buildReviewRows({
    locations: zandalarSourceLocations,
    exclusions: zandalarExclusions,
    worldsByKey,
    continentsByKey,
  });
  const kulTirasCapitalZoneIds = new Set([8568]);
  const kulTirasLocations = locations.filter(
    (location) => location.continentKey === "kul-tiras",
  );
  const kulTirasSourceLocations = kulTirasLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const kulTirasSyntheticLocations = kulTirasLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const kulTirasExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "kul-tiras",
  );
  const kulTirasReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 16,
    ).length,
    suppliedListEntries: 30,
    retainedEntries: kulTirasSourceLocations.length,
    canonicalLocationNodes: kulTirasLocations.length,
    syntheticRegions: kulTirasSyntheticLocations.length,
    subzones: kulTirasSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    displayedEntries: kulTirasSourceLocations.filter(
      (location) => !kulTirasCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalCandidates: kulTirasLocations.filter((location) =>
      kulTirasCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalOutsideDisplayedList: kulTirasLocations.filter(
      (location) => location.wowheadZoneId === 8568,
    ).length,
    excludedEntries: kulTirasExclusions.length,
    reviewedEntries: kulTirasLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: kulTirasLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(kulTirasLocations, (location) => location.kind),
    locations: kulTirasLocations,
    exclusions: kulTirasExclusions,
  };
  const kulTirasReviewRows = buildReviewRows({
    locations: kulTirasSourceLocations,
    exclusions: kulTirasExclusions,
    worldsByKey,
    continentsByKey,
  });
  const shadowlandsCapitalZoneIds = new Set([10565]);
  const shadowlandsLocations = locations.filter(
    (location) => location.continentKey === "shadowlands",
  );
  const shadowlandsSourceLocations = shadowlandsLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const shadowlandsSyntheticLocations = shadowlandsLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const shadowlandsExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "shadowlands",
  );
  const shadowlandsReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 17,
    ).length,
    suppliedListEntries: 28,
    retainedEntries: shadowlandsSourceLocations.length,
    canonicalLocationNodes: shadowlandsLocations.length,
    syntheticRegions: shadowlandsSyntheticLocations.length,
    subzones: shadowlandsSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    displayedEntries: shadowlandsSourceLocations.filter(
      (location) => !shadowlandsCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalCandidates: shadowlandsLocations.filter((location) =>
      shadowlandsCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalOutsideDisplayedList: shadowlandsLocations.filter(
      (location) => location.wowheadZoneId === 10565,
    ).length,
    excludedEntries: shadowlandsExclusions.length,
    reviewedEntries: shadowlandsLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: shadowlandsLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(shadowlandsLocations, (location) => location.kind),
    locations: shadowlandsLocations,
    exclusions: shadowlandsExclusions,
  };
  const shadowlandsReviewRows = buildReviewRows({
    locations: shadowlandsSourceLocations,
    exclusions: shadowlandsExclusions,
    worldsByKey,
    continentsByKey,
  });
  const dragonIslesCapitalZoneIds = new Set([13862]);
  const dragonIslesLocations = locations.filter(
    (location) => location.continentKey === "dragon-isles",
  );
  const dragonIslesSourceLocations = dragonIslesLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const dragonIslesSyntheticLocations = dragonIslesLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const dragonIslesExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "dragon-isles",
  );
  const dragonIslesReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 18,
    ).length,
    suppliedListEntries: 13,
    retainedEntries: dragonIslesSourceLocations.length,
    canonicalLocationNodes: dragonIslesLocations.length,
    syntheticRegions: dragonIslesSyntheticLocations.length,
    subzones: dragonIslesSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    displayedEntries: dragonIslesSourceLocations.filter(
      (location) => !dragonIslesCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalCandidates: dragonIslesLocations.filter((location) =>
      dragonIslesCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalOutsideDisplayedList: dragonIslesLocations.filter(
      (location) => location.wowheadZoneId === 13862,
    ).length,
    excludedEntries: dragonIslesExclusions.length,
    reviewedEntries: dragonIslesLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: dragonIslesLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(dragonIslesLocations, (location) => location.kind),
    locations: dragonIslesLocations,
    exclusions: dragonIslesExclusions,
  };
  const dragonIslesReviewRows = buildReviewRows({
    locations: dragonIslesSourceLocations,
    exclusions: dragonIslesExclusions,
    worldsByKey,
    continentsByKey,
  });
  const khazAlgarCapitalZoneIds = new Set([14771]);
  const khazAlgarLocations = locations.filter(
    (location) => location.continentKey === "khaz-algar",
  );
  const khazAlgarSourceLocations = khazAlgarLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const khazAlgarSyntheticLocations = khazAlgarLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const khazAlgarExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "khaz-algar",
  );
  const khazAlgarReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 19,
    ).length,
    suppliedListEntries: 23,
    retainedEntries: khazAlgarSourceLocations.length,
    canonicalLocationNodes: khazAlgarLocations.length,
    syntheticRegions: khazAlgarSyntheticLocations.length,
    subzones: khazAlgarSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    displayedEntries: khazAlgarSourceLocations.filter(
      (location) => !khazAlgarCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalCandidates: khazAlgarLocations.filter((location) =>
      khazAlgarCapitalZoneIds.has(location.wowheadZoneId),
    ).length,
    capitalOutsideDisplayedList: khazAlgarLocations.filter(
      (location) => location.wowheadZoneId === 14771,
    ).length,
    excludedEntries: khazAlgarExclusions.length,
    reviewedEntries: khazAlgarLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: khazAlgarLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(khazAlgarLocations, (location) => location.kind),
    locations: khazAlgarLocations,
    exclusions: khazAlgarExclusions,
  };
  const khazAlgarReviewRows = buildReviewRows({
    locations: khazAlgarSourceLocations,
    exclusions: khazAlgarExclusions,
    worldsByKey,
    continentsByKey,
  });
  const quelThalasLocations = locations.filter(
    (location) => location.continentKey === "quel-thalas",
  );
  const quelThalasSourceLocations = quelThalasLocations.filter(
    (location) => location.wowheadZoneId !== null,
  );
  const quelThalasSyntheticLocations = quelThalasLocations.filter(
    (location) => location.wowheadZoneId === null,
  );
  const quelThalasExclusions = exclusions.filter(
    (exclusion) => exclusion.continentKey === "quel-thalas",
  );
  const quelThalasReview = {
    sourceEntriesInWowheadCategory: (wowheadCatalog.zones ?? []).filter(
      (zone) => zone.wowheadCategoryId === 20,
    ).length,
    suppliedListEntries: 15,
    parentContinentKey: "eastern-kingdoms",
    retainedEntries: quelThalasSourceLocations.length,
    canonicalLocationNodes: quelThalasLocations.length,
    syntheticRegions: quelThalasSyntheticLocations.length,
    subzones: quelThalasSourceLocations.filter(
      (location) => location.kind === "subzone",
    ).length,
    excludedEntries: quelThalasExclusions.length,
    reviewedEntries: quelThalasLocations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingEntries: quelThalasLocations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byKind: countBy(quelThalasLocations, (location) => location.kind),
    locations: quelThalasLocations,
    exclusions: quelThalasExclusions,
  };
  const quelThalasReviewRows = buildReviewRows({
    locations: quelThalasSourceLocations,
    exclusions: quelThalasExclusions,
    worldsByKey,
    continentsByKey,
  });

  const audit = {
    sourceEntries: (wowheadCatalog.zones ?? []).length,
    worlds: config.worlds.length,
    continents: config.continents.length,
    canonicalLocations: locations.length,
    canonicalSemanticLocations: locations.filter(
      (location) => location.isCanonical,
    ).length,
    canonicalAliasGroups: canonicalAliases.length,
    sourceDerivedLocations: locations.filter(
      (location) => location.wowheadZoneId !== null,
    ).length,
    syntheticLocations: locations.filter(
      (location) => location.wowheadZoneId === null,
    ).length,
    exclusions: exclusions.length,
    unassignedSourceEntries: unassignedSourceEntries.length,
    sourceEntriesReconciled:
      locations.filter((location) => location.wowheadZoneId !== null).length +
      exclusions.length +
      unassignedSourceEntries.length,
    reviewedLocations: locations.filter(
      (location) => location.reviewStatus === "reviewed",
    ).length,
    pendingLocations: locations.filter(
      (location) => location.reviewStatus !== "reviewed",
    ).length,
    byWorld: countBy(locations, (location) => location.worldKey),
    byContinent: countBy(locations, (location) => location.continentKey),
    byKind: countBy(locations, (location) => location.kind),
    byReviewStatus: countBy(
      locations,
      (location) => location.reviewStatus,
    ),
    hierarchyErrors: [],
    kalimdor: {
      sourceEntries: kalimdorReview.sourceEntriesInWowheadCategory,
      retainedEntries: kalimdorReview.retainedEntries,
      excludedEntries: kalimdorReview.excludedEntries,
      reviewedEntries: kalimdorReview.reviewedEntries,
      pendingEntries: kalimdorReview.pendingEntries,
    },
    easternKingdoms: {
      sourceEntries: easternKingdomsReview.sourceEntriesInWowheadCategory,
      retainedEntries: easternKingdomsReview.retainedEntries,
      canonicalLocationNodes:
        easternKingdomsReview.canonicalLocationNodes,
      syntheticRegions: easternKingdomsReview.syntheticRegions,
      subzones: easternKingdomsReview.subzones,
      multiParentLocations: easternKingdomsReview.multiParentLocations,
      excludedEntries: easternKingdomsReview.excludedEntries,
      excludedByTestRule: easternKingdomsReview.excludedByTestRule,
      excludedByDoNotDisturbRule:
        easternKingdomsReview.excludedByDoNotDisturbRule,
      excludedByTechnicalMarkerRule:
        easternKingdomsReview.excludedByTechnicalMarkerRule,
      reviewedEntries: easternKingdomsReview.reviewedEntries,
      pendingEntries: easternKingdomsReview.pendingEntries,
    },
    outland: {
      sourceEntries: outlandReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: outlandReview.suppliedListEntries,
      retainedEntries: outlandReview.retainedEntries,
      displayedRegions: outlandReview.displayedRegions,
      capitalRegions: outlandReview.capitalRegions,
      excludedEntries: outlandReview.excludedEntries,
      reviewedEntries: outlandReview.reviewedEntries,
      pendingEntries: outlandReview.pendingEntries,
    },
    northrend: {
      sourceEntries: northrendReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: northrendReview.suppliedListEntries,
      retainedEntries: northrendReview.retainedEntries,
      syntheticRegions: northrendReview.syntheticRegions,
      subzones: northrendReview.subzones,
      displayedRegions: northrendReview.displayedRegions,
      capitalCandidates: northrendReview.capitalCandidates,
      capitalOutsideDisplayedList:
        northrendReview.capitalOutsideDisplayedList,
      deletedCapitalCandidates:
        northrendReview.deletedCapitalCandidates,
      excludedEntries: northrendReview.excludedEntries,
      reviewedEntries: northrendReview.reviewedEntries,
      pendingEntries: northrendReview.pendingEntries,
    },
    maelstrom: {
      sourceEntries: maelstromReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: maelstromReview.suppliedListEntries,
      retainedSourceRegions: maelstromReview.retainedSourceRegions,
      importedSubzones: maelstromReview.importedSubzones,
      canonicalLocationNodes: maelstromReview.canonicalLocationNodes,
      capitalRegions: maelstromReview.capitalRegions,
      excludedEntries: maelstromReview.excludedEntries,
      reviewedEntries: maelstromReview.reviewedEntries,
      pendingEntries: maelstromReview.pendingEntries,
    },
    pandaria: {
      sourceEntries: pandariaReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: pandariaReview.suppliedListEntries,
      unlistedEntries: pandariaReview.unlistedEntries,
      retainedEntries: pandariaReview.retainedEntries,
      canonicalLocationNodes: pandariaReview.canonicalLocationNodes,
      syntheticRegions: pandariaReview.syntheticRegions,
      subzones: pandariaReview.subzones,
      excludedEntries: pandariaReview.excludedEntries,
      reviewedEntries: pandariaReview.reviewedEntries,
      pendingEntries: pandariaReview.pendingEntries,
    },
    draenor: {
      sourceEntries: draenorReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: draenorReview.suppliedListEntries,
      unlistedEntries: draenorReview.unlistedEntries,
      retainedEntries: draenorReview.retainedEntries,
      canonicalLocationNodes: draenorReview.canonicalLocationNodes,
      syntheticRegions: draenorReview.syntheticRegions,
      subzones: draenorReview.subzones,
      excludedEntries: draenorReview.excludedEntries,
      reviewedEntries: draenorReview.reviewedEntries,
      pendingEntries: draenorReview.pendingEntries,
    },
    brokenIsles: {
      sourceEntries: brokenIslesReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: brokenIslesReview.suppliedListEntries,
      unlistedEntries: brokenIslesReview.unlistedEntries,
      retainedEntries: brokenIslesReview.retainedEntries,
      canonicalLocationNodes: brokenIslesReview.canonicalLocationNodes,
      syntheticRegions: brokenIslesReview.syntheticRegions,
      subzones: brokenIslesReview.subzones,
      excludedEntries: brokenIslesReview.excludedEntries,
      reviewedEntries: brokenIslesReview.reviewedEntries,
      pendingEntries: brokenIslesReview.pendingEntries,
    },
    zandalar: {
      sourceEntries: zandalarReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: zandalarReview.suppliedListEntries,
      retainedEntries: zandalarReview.retainedEntries,
      canonicalLocationNodes: zandalarReview.canonicalLocationNodes,
      syntheticRegions: zandalarReview.syntheticRegions,
      subzones: zandalarReview.subzones,
      displayedEntries: zandalarReview.displayedEntries,
      capitalCandidates: zandalarReview.capitalCandidates,
      capitalOutsideDisplayedList:
        zandalarReview.capitalOutsideDisplayedList,
      excludedEntries: zandalarReview.excludedEntries,
      reviewedEntries: zandalarReview.reviewedEntries,
      pendingEntries: zandalarReview.pendingEntries,
    },
    kulTiras: {
      sourceEntries: kulTirasReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: kulTirasReview.suppliedListEntries,
      retainedEntries: kulTirasReview.retainedEntries,
      canonicalLocationNodes: kulTirasReview.canonicalLocationNodes,
      syntheticRegions: kulTirasReview.syntheticRegions,
      subzones: kulTirasReview.subzones,
      displayedEntries: kulTirasReview.displayedEntries,
      capitalCandidates: kulTirasReview.capitalCandidates,
      capitalOutsideDisplayedList:
        kulTirasReview.capitalOutsideDisplayedList,
      excludedEntries: kulTirasReview.excludedEntries,
      reviewedEntries: kulTirasReview.reviewedEntries,
      pendingEntries: kulTirasReview.pendingEntries,
    },
    shadowlands: {
      sourceEntries: shadowlandsReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: shadowlandsReview.suppliedListEntries,
      retainedEntries: shadowlandsReview.retainedEntries,
      canonicalLocationNodes: shadowlandsReview.canonicalLocationNodes,
      syntheticRegions: shadowlandsReview.syntheticRegions,
      subzones: shadowlandsReview.subzones,
      displayedEntries: shadowlandsReview.displayedEntries,
      capitalCandidates: shadowlandsReview.capitalCandidates,
      capitalOutsideDisplayedList:
        shadowlandsReview.capitalOutsideDisplayedList,
      excludedEntries: shadowlandsReview.excludedEntries,
      reviewedEntries: shadowlandsReview.reviewedEntries,
      pendingEntries: shadowlandsReview.pendingEntries,
    },
    dragonIsles: {
      sourceEntries: dragonIslesReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: dragonIslesReview.suppliedListEntries,
      retainedEntries: dragonIslesReview.retainedEntries,
      canonicalLocationNodes: dragonIslesReview.canonicalLocationNodes,
      syntheticRegions: dragonIslesReview.syntheticRegions,
      subzones: dragonIslesReview.subzones,
      displayedEntries: dragonIslesReview.displayedEntries,
      capitalCandidates: dragonIslesReview.capitalCandidates,
      capitalOutsideDisplayedList:
        dragonIslesReview.capitalOutsideDisplayedList,
      excludedEntries: dragonIslesReview.excludedEntries,
      reviewedEntries: dragonIslesReview.reviewedEntries,
      pendingEntries: dragonIslesReview.pendingEntries,
    },
    khazAlgar: {
      sourceEntries: khazAlgarReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: khazAlgarReview.suppliedListEntries,
      retainedEntries: khazAlgarReview.retainedEntries,
      canonicalLocationNodes: khazAlgarReview.canonicalLocationNodes,
      syntheticRegions: khazAlgarReview.syntheticRegions,
      subzones: khazAlgarReview.subzones,
      displayedEntries: khazAlgarReview.displayedEntries,
      capitalCandidates: khazAlgarReview.capitalCandidates,
      capitalOutsideDisplayedList:
        khazAlgarReview.capitalOutsideDisplayedList,
      excludedEntries: khazAlgarReview.excludedEntries,
      reviewedEntries: khazAlgarReview.reviewedEntries,
      pendingEntries: khazAlgarReview.pendingEntries,
    },
    quelThalas: {
      sourceEntries: quelThalasReview.sourceEntriesInWowheadCategory,
      suppliedListEntries: quelThalasReview.suppliedListEntries,
      parentContinentKey: quelThalasReview.parentContinentKey,
      retainedEntries: quelThalasReview.retainedEntries,
      canonicalLocationNodes: quelThalasReview.canonicalLocationNodes,
      syntheticRegions: quelThalasReview.syntheticRegions,
      subzones: quelThalasReview.subzones,
      excludedEntries: quelThalasReview.excludedEntries,
      reviewedEntries: quelThalasReview.reviewedEntries,
      pendingEntries: quelThalasReview.pendingEntries,
    },
  };

  const output = {
    schemaVersion: config.schemaVersion,
    hierarchy: "world > continent > location(parentRef)",
    locationKinds: {
      region: "Zone géographique principale",
      subzone: "Zone rattachée à une autre localisation",
    },
    worlds: config.worlds,
    continents: config.continents,
    canonicalAliases,
    locations,
    exclusions,
    unassignedSourceEntries,
  };

  await Promise.all([
    fs.writeFile(paths.output, `${JSON.stringify(output, null, 2)}\n`, "utf8"),
    fs.writeFile(paths.audit, `${JSON.stringify(audit, null, 2)}\n`, "utf8"),
    fs.writeFile(
      paths.kalimdorReview,
      `${JSON.stringify(kalimdorReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.kalimdorReviewCsv,
      `${toSemicolonCsv(kalimdorReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.easternKingdomsReview,
      `${JSON.stringify(easternKingdomsReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.easternKingdomsCatalogCsv,
      `${toSemicolonCsv(easternKingdomsReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.outlandReview,
      `${JSON.stringify(outlandReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.outlandReviewCsv,
      `${toSemicolonCsv(outlandReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.northrendReview,
      `${JSON.stringify(northrendReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.northrendCatalogCsv,
      `${toSemicolonCsv(northrendReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.maelstromReview,
      `${JSON.stringify(maelstromReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.maelstromReviewCsv,
      `${toSemicolonCsv(maelstromReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.pandariaReview,
      `${JSON.stringify(pandariaReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.pandariaReviewCsv,
      `${toSemicolonCsv(pandariaReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.draenorReview,
      `${JSON.stringify(draenorReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.draenorReviewCsv,
      `${toSemicolonCsv(draenorReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.brokenIslesReview,
      `${JSON.stringify(brokenIslesReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.brokenIslesReviewCsv,
      `${toSemicolonCsv(brokenIslesReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.zandalarReview,
      `${JSON.stringify(zandalarReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.zandalarReviewCsv,
      `${toSemicolonCsv(zandalarReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.kulTirasReview,
      `${JSON.stringify(kulTirasReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.kulTirasReviewCsv,
      `${toSemicolonCsv(kulTirasReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.shadowlandsReview,
      `${JSON.stringify(shadowlandsReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.shadowlandsReviewCsv,
      `${toSemicolonCsv(shadowlandsReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.dragonIslesReview,
      `${JSON.stringify(dragonIslesReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.dragonIslesReviewCsv,
      `${toSemicolonCsv(dragonIslesReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.khazAlgarReview,
      `${JSON.stringify(khazAlgarReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.khazAlgarReviewCsv,
      `${toSemicolonCsv(khazAlgarReviewRows)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.quelThalasReview,
      `${JSON.stringify(quelThalasReview, null, 2)}\n`,
      "utf8",
    ),
    fs.writeFile(
      paths.quelThalasReviewCsv,
      `${toSemicolonCsv(quelThalasReviewRows)}\n`,
      "utf8",
    ),
  ]);

  console.log(
    [
      `${audit.worlds} mondes`,
      `${audit.continents} continents`,
      `${audit.canonicalLocations} localisations`,
      `${audit.unassignedSourceEntries} entrées à affecter`,
      `Kalimdor: ${kalimdorReview.reviewedEntries} validées, ${kalimdorReview.pendingEntries} à revoir, ${kalimdorReview.excludedEntries} supprimées`,
      `Royaumes de l'Est: ${easternKingdomsReview.retainedEntries} entrées retenues, ${easternKingdomsReview.subzones} sous-zones, ${easternKingdomsReview.syntheticRegions} régions créées, ${easternKingdomsReview.excludedEntries} supprimées`,
      `Outreterre: ${outlandReview.displayedRegions} régions et ${outlandReview.capitalRegions} capitale validées`,
      `Norfendre: ${northrendReview.retainedEntries} entrées retenues, ${northrendReview.subzones} sous-zone, ${northrendReview.excludedEntries} supprimées et ${northrendReview.pendingEntries} à revoir`,
      `Le Maelström: ${maelstromReview.retainedSourceRegions} régions, ${maelstromReview.importedSubzones} sous-zone importée et ${maelstromReview.pendingEntries} à revoir`,
      `Pandarie: ${pandariaReview.retainedEntries} entrées conservées, ${pandariaReview.subzones} sous-zones, ${pandariaReview.syntheticRegions} régions créées, ${pandariaReview.excludedEntries} supprimées et ${pandariaReview.pendingEntries} à revoir`,
      `Draenor: ${draenorReview.retainedEntries} entrées conservées, ${draenorReview.subzones} sous-zones, ${draenorReview.syntheticRegions} régions créées, ${draenorReview.excludedEntries} supprimées et ${draenorReview.pendingEntries} à revoir`,
      `Îles Brisées: ${brokenIslesReview.retainedEntries} entrées conservées, ${brokenIslesReview.subzones} sous-zones, ${brokenIslesReview.syntheticRegions} régions créées, ${brokenIslesReview.excludedEntries} supprimées et ${brokenIslesReview.pendingEntries} à revoir`,
      `Zandalar: ${zandalarReview.retainedEntries} entrées conservées, ${zandalarReview.subzones} sous-zones, ${zandalarReview.capitalCandidates} capitale, ${zandalarReview.excludedEntries} supprimées et ${zandalarReview.pendingEntries} à revoir`,
      `Kul Tiras: ${kulTirasReview.retainedEntries} entrées conservées, ${kulTirasReview.subzones} sous-zones, ${kulTirasReview.capitalCandidates} capitale, ${kulTirasReview.excludedEntries} supprimées et ${kulTirasReview.pendingEntries} à revoir`,
      `Ombreterre: ${shadowlandsReview.retainedEntries} entrées conservées, ${shadowlandsReview.subzones} sous-zones, ${shadowlandsReview.capitalCandidates} capitale, ${shadowlandsReview.excludedEntries} supprimées et ${shadowlandsReview.pendingEntries} à revoir`,
      `Îles aux Dragons: ${dragonIslesReview.retainedEntries} entrées conservées, ${dragonIslesReview.subzones} sous-zones, ${dragonIslesReview.capitalCandidates} capitale, ${dragonIslesReview.excludedEntries} supprimées et ${dragonIslesReview.pendingEntries} à revoir`,
      `Khaz Algar: ${khazAlgarReview.retainedEntries} entrées conservées, ${khazAlgarReview.subzones} sous-zones, ${khazAlgarReview.capitalCandidates} capitale, ${khazAlgarReview.excludedEntries} supprimées et ${khazAlgarReview.pendingEntries} à revoir`,
      `Quel'Thalas: ${quelThalasReview.retainedEntries} entrées conservées, ${quelThalasReview.subzones} sous-zones, ${quelThalasReview.excludedEntries} supprimées et ${quelThalasReview.pendingEntries} à revoir, sous les Royaumes de l'Est`,
    ].join(" | "),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
