import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const repoRoot = "D:/WoW100";
const sourcePath = path.join(
  repoRoot,
  "assets/generated/zones_wowhead_catalog.json",
);
const outputDir = path.join(repoRoot, "outputs/zones-reference-2026-06-19");
const outputPath = path.join(outputDir, "referentiel-zones-wow100.xlsx");
const previewDir = path.join(outputDir, "previews");

const source = JSON.parse(await fs.readFile(sourcePath, "utf8"));
const zones = [...(source.zones ?? [])].sort((a, b) =>
  `${a.geographicRegionName}|${a.name}|${a.id}`.localeCompare(
    `${b.geographicRegionName}|${b.name}|${b.id}`,
    "fr",
  ),
);

function countBy(values, selector) {
  const result = new Map();
  for (const value of values) {
    const key = selector(value) || "Non renseigné";
    result.set(key, (result.get(key) ?? 0) + 1);
  }
  return [...result.entries()].sort(
    (a, b) => b[1] - a[1] || a[0].localeCompare(b[0], "fr"),
  );
}

function columnName(number) {
  let value = number;
  let name = "";
  while (value > 0) {
    const remainder = (value - 1) % 26;
    name = String.fromCharCode(65 + remainder) + name;
    value = Math.floor((value - 1) / 26);
  }
  return name;
}

const byNormalizedName = new Map();
for (const zone of zones) {
  const key = zone.normalizedName || zone.name.toLocaleLowerCase("fr");
  const matches = byNormalizedName.get(key) ?? [];
  matches.push(zone);
  byNormalizedName.set(key, matches);
}
const duplicateGroups = [...byNormalizedName.values()]
  .filter((matches) => matches.length > 1)
  .sort((a, b) =>
    a[0].name.localeCompare(b[0].name, "fr"),
  );

const regionCounts = countBy(zones, (zone) => zone.geographicRegionName);
const expansionCounts = countBy(zones, (zone) => zone.expansionName);
const typeCounts = countBy(zones, (zone) => zone.instanceTypeName);
const categoryCounts = countBy(zones, (zone) => zone.wowheadCategoryName);
const plainZoneCount = zones.filter(
  (zone) => zone.instanceTypeName === "Zone",
).length;

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Synthèse");
const catalog = workbook.worksheets.add("Catalogue complet");
const duplicates = workbook.worksheets.add("Noms en doublon");

const navy = "#172033";
const teal = "#0F766E";
const amber = "#D97706";
const soft = "#F3F6F8";
const paleTeal = "#DFF3EF";
const paleAmber = "#FFF2D8";
const border = "#CBD5E1";
const white = "#FFFFFF";
const text = "#1F2937";

summary.showGridLines = false;
summary.mergeCells("A1:H2");
summary.getRange("A1").values = [["Référentiel des zones WoW100"]];
summary.getRange("A1:H2").format = {
  fill: navy,
  font: { bold: true, color: white, size: 20 },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
summary.getRange("A4:B4").values = [["Indicateur", "Valeur"]];
summary.getRange("A5:A9").values = [
  ["Entrées Wowhead"],
  ["Régions géographiques"],
  ["Catégories Wowhead"],
  ["Entrées de type Zone"],
  ["Groupes de noms en doublon"],
];
summary.getRange("B5:B9").formulas = [
  [`=COUNTA('Catalogue complet'!A2:A${zones.length + 1})`],
  [`=COUNTA(D15:D${14 + regionCounts.length})`],
  [`=COUNTA(G15:G${14 + categoryCounts.length})`],
  [`=COUNTIF('Catalogue complet'!H2:H${zones.length + 1},"Zone")`],
  [`=COUNTA('Noms en doublon'!A2:A${duplicateGroups.length + 1})`],
];
summary.getRange("A4:B9").format.borders = {
  preset: "all",
  style: "thin",
  color: border,
};
summary.getRange("A4:B4").format = {
  fill: teal,
  font: { bold: true, color: white },
};
summary.getRange("A5:A9").format.fill = soft;
summary.getRange("B5:B9").format.font = { bold: true, color: navy };

summary.mergeCells("D4:H4");
summary.getRange("D4").values = [["Ce que le catalogue sait, et ce qu’il ne sait pas"]];
summary.getRange("D4:H4").format = {
  fill: amber,
  font: { bold: true, color: white },
};
summary.mergeCells("D5:H6");
summary.getRange("D5").values = [[
  "Sûr : nom, continent/catégorie, région géographique, extension, type d’instance et niveaux.",
]];
summary.getRange("D5:H6").format = {
  fill: paleTeal,
  font: { color: text },
  wrapText: true,
  verticalAlignment: "center",
};
summary.mergeCells("D7:H9");
summary.getRange("D7").values = [[
  "Absent : le parent direct d’une sous-zone. Aujourd’hui, Île aux Sirènes et Chambre Oubliée sont deux lignes au même niveau. Ajouter Zone principale + Sous-zone permettrait de conserver les deux sans confondre leur portée.",
]];
summary.getRange("D7:H9").format = {
  fill: paleAmber,
  font: { color: text },
  wrapText: true,
  verticalAlignment: "center",
};
summary.getRange("D4:H9").format.borders = {
  preset: "outside",
  style: "thin",
  color: border,
};

summary.mergeCells("A11:H11");
summary.getRange("A11").values = [["Exemple concret de hiérarchie proposée"]];
summary.getRange("A11:H11").format = {
  fill: teal,
  font: { bold: true, color: white },
};
summary.getRange("A12:H13").values = [
  ["Extension", "Continent", "Zone principale", "Sous-zone", "Statut", "Zone ID principale", "Sous-zone ID", "Remarque"],
  ["The War Within", "Khaz Algar", "Île aux Sirènes", "Chambre Oubliée", "Relation à confirmer", 10416, 15827, "Le référentiel actuel ne contient pas ce lien parent-enfant."],
];
summary.getRange("A12:H12").format = {
  fill: navy,
  font: { bold: true, color: white },
  wrapText: true,
};
summary.getRange("A13:H13").format = {
  fill: paleAmber,
  wrapText: true,
  borders: { preset: "all", style: "thin", color: border },
};

summary.getRange("A15:B15").values = [["Type d’instance", "Nombre"]];
summary.getRange(`A16:B${15 + typeCounts.length}`).values = typeCounts;
summary.getRange("A15:B15").format = {
  fill: navy,
  font: { bold: true, color: white },
};
summary.getRange(`A15:B${15 + typeCounts.length}`).format.borders = {
  preset: "all",
  style: "thin",
  color: border,
};

summary.getRange("D15:E15").values = [["Région géographique", "Nombre"]];
summary.getRange(`D16:E${15 + regionCounts.length}`).values = regionCounts;
summary.getRange("D15:E15").format = {
  fill: teal,
  font: { bold: true, color: white },
};
summary.getRange(`D15:E${15 + regionCounts.length}`).format.borders = {
  preset: "all",
  style: "thin",
  color: border,
};

summary.getRange("G15:H15").values = [["Catégorie Wowhead", "Nombre"]];
summary.getRange(`G16:H${15 + categoryCounts.length}`).values = categoryCounts;
summary.getRange("G15:H15").format = {
  fill: amber,
  font: { bold: true, color: white },
};
summary.getRange(`G15:H${15 + categoryCounts.length}`).format.borders = {
  preset: "all",
  style: "thin",
  color: border,
};

const chartRangeEnd = Math.min(15 + typeCounts.length, 24);
const chart = summary.charts.add("bar", summary.getRange(`A15:B${chartRangeEnd}`));
chart.title = "Répartition par type d’instance";
chart.hasLegend = false;
chart.setPosition("J4", "Q19");

summary.freezePanes.freezeRows(2);
summary.getRange("A:A").format.columnWidth = 22;
summary.getRange("B:B").format.columnWidth = 16;
summary.getRange("C:C").format.columnWidth = 24;
summary.getRange("D:D").format.columnWidth = 24;
summary.getRange("E:E").format.columnWidth = 20;
summary.getRange("F:F").format.columnWidth = 16;
summary.getRange("G:G").format.columnWidth = 16;
summary.getRange("H:H").format.columnWidth = 38;
summary.getRange("J:Q").format.columnWidth = 12;

const catalogHeaders = [
  "ID Wowhead",
  "Nom",
  "Catégorie Wowhead",
  "Région géographique",
  "Extension",
  "Patch de base",
  "Patch exact",
  "Type d’instance",
  "Niveau",
  "Territoire",
  "Parent direct connu",
  "Lecture actuelle",
  "URL Wowhead",
];
const catalogRows = zones.map((zone) => [
  zone.id,
  zone.name,
  zone.wowheadCategoryName,
  zone.geographicRegionName,
  zone.expansionName,
  zone.expansionBasePatch,
  zone.patch ?? "Non fourni",
  zone.instanceTypeName,
  zone.minLevel === zone.maxLevel
    ? String(zone.minLevel)
    : `${zone.minLevel}-${zone.maxLevel}`,
  zone.territoryName,
  "Non fourni",
  zone.instanceTypeName === "Zone"
    ? "Zone ou sous-zone non distinguée"
    : zone.instanceTypeName,
  zone.wowheadUrl,
]);
catalog.showGridLines = false;
catalog.getRange(`A1:${columnName(catalogHeaders.length)}1`).values = [catalogHeaders];
catalog.getRange(
  `A2:${columnName(catalogHeaders.length)}${catalogRows.length + 1}`,
).values = catalogRows;
catalog.getRange(`A1:${columnName(catalogHeaders.length)}1`).format = {
  fill: navy,
  font: { bold: true, color: white },
  wrapText: true,
  verticalAlignment: "center",
};
catalog.getRange(
  `A2:${columnName(catalogHeaders.length)}${catalogRows.length + 1}`,
).format.borders = { preset: "all", style: "thin", color: "#E5E7EB" };
catalog.tables.add(
  `A1:${columnName(catalogHeaders.length)}${catalogRows.length + 1}`,
  true,
  "ZonesReferenceTable",
);
catalog.freezePanes.freezeRows(1);
catalog.freezePanes.freezeColumns(2);
const catalogWidths = [12, 34, 23, 23, 22, 15, 15, 18, 10, 15, 20, 33, 42];
catalogWidths.forEach((width, index) => {
  catalog.getRange(`${columnName(index + 1)}:${columnName(index + 1)}`).format.columnWidth = width;
});
catalog.getRange("K2:K1255").format.fill = paleAmber;
catalog.getRange("L2:L1255").format.wrapText = true;

const duplicateHeaders = [
  "Nom normalisé",
  "Nombre d’IDs",
  "Noms affichés",
  "IDs Wowhead",
  "Régions",
  "Extensions",
  "Types",
  "URLs",
];
const duplicateRows = duplicateGroups.map((matches) => [
  matches[0].normalizedName,
  matches.length,
  [...new Set(matches.map((zone) => zone.name))].join(" | "),
  matches.map((zone) => zone.id).join(" | "),
  [...new Set(matches.map((zone) => zone.geographicRegionName))].join(" | "),
  [...new Set(matches.map((zone) => zone.expansionName))].join(" | "),
  [...new Set(matches.map((zone) => zone.instanceTypeName))].join(" | "),
  matches.map((zone) => zone.wowheadUrl).join(" | "),
]);
duplicates.showGridLines = false;
duplicates.getRange("A1:H1").values = [duplicateHeaders];
if (duplicateRows.length) {
  duplicates.getRange(`A2:H${duplicateRows.length + 1}`).values = duplicateRows;
  duplicates.tables.add(
    `A1:H${duplicateRows.length + 1}`,
    true,
    "DuplicateZoneNamesTable",
  );
}
duplicates.getRange("A1:H1").format = {
  fill: amber,
  font: { bold: true, color: white },
  wrapText: true,
};
duplicates.getRange(`A1:H${Math.max(2, duplicateRows.length + 1)}`).format.borders = {
  preset: "all",
  style: "thin",
  color: border,
};
duplicates.freezePanes.freezeRows(1);
[24, 13, 36, 24, 28, 24, 20, 52].forEach((width, index) => {
  duplicates.getRange(`${columnName(index + 1)}:${columnName(index + 1)}`).format.columnWidth = width;
});

await fs.mkdir(previewDir, { recursive: true });
for (const sheetName of ["Synthèse", "Catalogue complet", "Noms en doublon"]) {
  const preview = await workbook.render({
    sheetName,
    autoCrop: "all",
    scale: sheetName === "Synthèse" ? 1 : 0.7,
    format: "png",
  });
  const filename = sheetName
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-zA-Z0-9]+/g, "-")
    .toLowerCase();
  await fs.writeFile(
    path.join(previewDir, `${filename}.png`),
    new Uint8Array(await preview.arrayBuffer()),
  );
}

const inspect = await workbook.inspect({
  kind: "table",
  range: "Synthèse!A1:H20",
  include: "values,formulas",
  tableMaxRows: 20,
  tableMaxCols: 8,
});
const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "final formula error scan",
});

await fs.mkdir(outputDir, { recursive: true });
const file = await SpreadsheetFile.exportXlsx(workbook);
await file.save(outputPath);

console.log(
  JSON.stringify(
    {
      outputPath,
      totalZones: zones.length,
      plainZoneCount,
      regions: regionCounts.length,
      categories: categoryCounts.length,
      duplicateGroups: duplicateGroups.length,
      typeCounts: Object.fromEntries(typeCounts),
      inspect: inspect.ndjson,
      errors: errors.ndjson,
    },
    null,
    2,
  ),
);
