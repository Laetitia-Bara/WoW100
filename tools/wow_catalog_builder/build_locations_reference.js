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
    "regionRefOverride",
    "regionNameOverride",
    "reviewStatus",
    "note",
  ]) {
    if (rule[field] !== undefined) location[field] = rule[field];
  }
  location.source = "wowhead_zone_catalog_and_manual_review";
  location.parentRefs = [location.parentRef];
  if (rule.reviewStatus === "reviewed") {
    location.reviewMethod = "user_manual_rule";
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

function buildPath(location, locationsByRef, worldsByKey, continentsByKey) {
  const world = worldsByKey.get(location.worldKey);
  const continent = continentsByKey.get(location.continentKey);
  const locationNames = [];
  let cursor = location;

  while (cursor) {
    locationNames.unshift(cursor.name);
    if (cursor.parentRef.startsWith("continent:")) break;
    cursor = locationsByRef.get(cursor.parentRef);
  }

  return [world?.name, continent?.name, ...locationNames].filter(Boolean);
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
        reviewBatch: "eastern-kingdoms-manual-review",
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
    if (sameRegion) {
      decisions.push({
        ...row,
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
      action: "keep",
      kind: capitalZoneIdSet.has(row.wowheadZoneId)
        ? "region"
        : "subzone",
      parentRef: parentRefs[0],
      parentRefs,
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
  location.reviewBatch = "eastern-kingdoms-manual-review";
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
  const [wowheadCatalog, config, easternKingdomsManualReview] =
    await Promise.all([
    loadJson(paths.wowheadCatalog),
    loadJson(paths.overrides),
      loadJson(paths.easternKingdomsManualReview),
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

  for (const continent of config.continents) {
    if (!worldsByKey.has(continent.worldKey)) {
      throw new Error(
        `Monde ${continent.worldKey} introuvable pour ${continent.key}`,
      );
    }
  }

  const exclusions = [];
  const unassignedSourceEntries = [];
  const locations = [];

  for (const zone of wowheadCatalog.zones ?? []) {
    const continent = continentsByWowheadCategoryId.get(
      zone.wowheadCategoryId,
    );
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

    const rule = rulesByZoneId.get(zone.id);
    const manualDecision =
      continent.key === "eastern-kingdoms"
        ? easternKingdomsManual.decisionsByZoneId.get(zone.id)
        : null;
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

  const audit = {
    sourceEntries: (wowheadCatalog.zones ?? []).length,
    worlds: config.worlds.length,
    continents: config.continents.length,
    canonicalLocations: locations.length,
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
  ]);

  console.log(
    [
      `${audit.worlds} mondes`,
      `${audit.continents} continents`,
      `${audit.canonicalLocations} localisations`,
      `${audit.unassignedSourceEntries} entrées à affecter`,
      `Kalimdor: ${kalimdorReview.reviewedEntries} validées, ${kalimdorReview.pendingEntries} à revoir, ${kalimdorReview.excludedEntries} supprimées`,
      `Royaumes de l'Est: ${easternKingdomsReview.retainedEntries} entrées retenues, ${easternKingdomsReview.subzones} sous-zones, ${easternKingdomsReview.syntheticRegions} régions créées, ${easternKingdomsReview.excludedEntries} supprimées`,
    ].join(" | "),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
