import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");

async function loadJson(relativePath) {
  return JSON.parse(await fs.readFile(path.join(repoRoot, relativePath), "utf8"));
}

function ensure(condition, message) {
  if (!condition) throw new Error(message);
}

async function main() {
  const [locationsCatalog, mountsCatalog, assignmentsCatalog] =
    await Promise.all([
      loadJson("assets/generated/locations_reference_catalog.json"),
      loadJson("assets/generated/mounts_reference_catalog.json"),
      loadJson("assets/data/metadata/mount_location_assignments.json"),
    ]);

  const locationsByRef = new Map(
    locationsCatalog.locations.map((location) => [location.ref, location]),
  );
  const mountsById = new Map(
    mountsCatalog.mounts.map((mount) => [mount.blizzardId, mount]),
  );
  const assignmentIds = new Set();

  for (const location of locationsCatalog.locations) {
    ensure(
      locationsByRef.has(location.canonicalRef),
      `Reference canonique absente pour ${location.ref}: ${location.canonicalRef}`,
    );
  }

  for (const assignment of assignmentsCatalog.assignments ?? []) {
    ensure(
      !assignmentIds.has(assignment.blizzardId),
      `Decision manuelle dupliquee pour la monture ${assignment.blizzardId}`,
    );
    assignmentIds.add(assignment.blizzardId);
    ensure(
      mountsById.has(assignment.blizzardId),
      `Monture manuelle inconnue: ${assignment.blizzardId}`,
    );
    ensure(
      locationsByRef.has(assignment.primaryLocationRef),
      `Localisation manuelle inconnue: ${assignment.primaryLocationRef}`,
    );
  }

  let assigned = 0;
  for (const mount of mountsCatalog.mounts) {
    if (!mount.primaryLocationRef) {
      ensure(
        mount.location === null,
        `La monture ${mount.blizzardId} a un lieu sans primaryLocationRef`,
      );
      continue;
    }

    assigned += 1;
    const location = locationsByRef.get(mount.primaryLocationRef);
    ensure(
      location,
      `Reference de monture inconnue ${mount.primaryLocationRef} pour ${mount.blizzardId}`,
    );
    ensure(
      mount.primaryLocationRef === location.canonicalRef,
      `Reference non canonique pour la monture ${mount.blizzardId}`,
    );
    ensure(
      mount.location?.worldName &&
        mount.location?.continentName &&
        mount.location?.regionName &&
        mount.location?.pathLabel,
      `Hierarchie incomplete pour la monture ${mount.blizzardId}`,
    );
    for (const locationRef of mount.locationRefs ?? []) {
      ensure(
        locationsByRef.has(locationRef),
        `Reference secondaire inconnue ${locationRef} pour ${mount.blizzardId}`,
      );
    }
  }

  console.log(
    `${assigned} montures localisees | ${assignmentIds.size} decisions manuelles | aucune reference orpheline`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
