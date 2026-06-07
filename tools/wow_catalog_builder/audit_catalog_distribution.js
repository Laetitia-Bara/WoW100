import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
const generatedDir = path.join(repoRoot, "assets/generated");
const outputPath = path.join(generatedDir, "catalog_distribution_audit_report.json");

const paths = {
  petsDraft: path.join(generatedDir, "pets_wow100_draft.json"),
  petWowheadIndex: path.join(generatedDir, "pets_wowhead_expansion_index.json"),
  achievementsDraft: path.join(generatedDir, "achievements_wow100_draft.json"),
  achievementWowheadIndex: path.join(generatedDir, "achievements_wowhead_index.json"),
  patchAudit: path.join(generatedDir, "wowhead_patch_audit_report.json"),
};

async function loadJson(filePath, fallback) {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") return fallback;
    throw error;
  }
}

function isClassified(expansion) {
  return Boolean(
    expansion &&
      !["allMounts", "allPets", "allAchievements", "unknown"].includes(expansion),
  );
}

function auditPets(pets, wowheadIndex) {
  const mismatches = [];
  const missingFromWowheadIndex = [];

  for (const pet of pets) {
    const wowhead = wowheadIndex[pet.blizzardId];

    if (!wowhead) {
      missingFromWowheadIndex.push({
        blizzardId: pet.blizzardId,
        name: pet.name,
        currentExpansion: pet.expansion,
      });
      continue;
    }

    if (pet.expansion !== wowhead.expansion) {
      mismatches.push({
        blizzardId: pet.blizzardId,
        name: pet.name,
        currentExpansion: pet.expansion,
        wowheadExpansion: wowhead.expansion,
        wowheadUrl: wowhead.wowheadUrl,
      });
    }
  }

  return {
    total: pets.length,
    wowheadIndexRows: Object.keys(wowheadIndex).length,
    classified: pets.filter((pet) => isClassified(pet.expansion)).length,
    unclassified: pets.filter((pet) => !isClassified(pet.expansion)).length,
    mismatches,
    missingFromWowheadIndex,
  };
}

function auditAchievements(achievements, wowheadIndex) {
  const rowsWithWowheadIndex = achievements.filter(
    (achievement) => wowheadIndex[achievement.blizzardId],
  );
  const rowsWithWowheadExpansion = rowsWithWowheadIndex.filter(
    (achievement) => wowheadIndex[achievement.blizzardId]?.expansion,
  );
  const mismatches = rowsWithWowheadExpansion
    .filter(
      (achievement) =>
        achievement.expansion !== wowheadIndex[achievement.blizzardId].expansion,
    )
    .map((achievement) => ({
      blizzardId: achievement.blizzardId,
      name: achievement.name,
      currentExpansion: achievement.expansion,
      wowheadExpansion: wowheadIndex[achievement.blizzardId].expansion,
      wowheadUrl: wowheadIndex[achievement.blizzardId].wowheadUrl,
    }));

  return {
    total: achievements.length,
    wowheadIndexRows: Object.keys(wowheadIndex).length,
    rowsWithWowheadIndex: rowsWithWowheadIndex.length,
    rowsWithWowheadExpansion: rowsWithWowheadExpansion.length,
    classified: achievements.filter((achievement) =>
      isClassified(achievement.expansion),
    ).length,
    unclassified: achievements.filter(
      (achievement) => !isClassified(achievement.expansion),
    ).length,
    mismatches,
    limitation:
      "L'index Wowhead local des hauts faits ne contient que les 1000 premiers résultats et aucun champ expansion exploitable. Utiliser wowhead_patch_audit_report.json pour l'audit par page quand Wowhead ne bloque pas les requêtes.",
  };
}

async function main() {
  const pets = await loadJson(paths.petsDraft, []);
  const petWowheadIndex = (await loadJson(paths.petWowheadIndex, { pets: {} })).pets ?? {};
  const achievements = await loadJson(paths.achievementsDraft, []);
  const achievementWowheadIndex =
    (await loadJson(paths.achievementWowheadIndex, { achievements: {} }))
      .achievements ?? {};
  const patchAudit = await loadJson(paths.patchAudit, null);

  const report = {
    generatedAt: new Date().toISOString(),
    pets: auditPets(pets, petWowheadIndex),
    achievements: auditAchievements(achievements, achievementWowheadIndex),
    mountsPatchAuditSummary: patchAudit
      ? {
          audited: patchAudit.audited,
          byStatus: patchAudit.byStatus,
          byKind: patchAudit.byKind,
          mismatches: patchAudit.mismatches?.length ?? 0,
          unclassifiedWithPatch: patchAudit.unclassifiedWithPatch?.length ?? 0,
          availabilityOverrides: patchAudit.availabilityOverrides?.length ?? 0,
          patchMissing: patchAudit.patchMissing?.length ?? 0,
          fetchFailed: patchAudit.fetchFailed?.length ?? 0,
        }
      : null,
  };

  await fs.writeFile(outputPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");

  console.log(
    JSON.stringify(
      {
        reportPath: path.relative(repoRoot, outputPath),
        pets: {
          total: report.pets.total,
          mismatches: report.pets.mismatches.length,
          missingFromWowheadIndex: report.pets.missingFromWowheadIndex.length,
        },
        achievements: {
          total: report.achievements.total,
          classified: report.achievements.classified,
          unclassified: report.achievements.unclassified,
          comparableWowheadRows: report.achievements.rowsWithWowheadExpansion,
          mismatches: report.achievements.mismatches.length,
        },
        mountsPatchAuditSummary: report.mountsPatchAuditSummary,
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
