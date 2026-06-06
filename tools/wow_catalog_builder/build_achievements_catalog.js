import axios from "axios";
import dotenv from "dotenv";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

dotenv.config({ quiet: true });

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");

const generatedDir = path.join(repoRoot, "assets/generated");
const achievementDataDir = path.join(repoRoot, "assets/data/achievements");
const metadataPath = path.join(
  repoRoot,
  "assets/data/metadata/achievements_metadata.json",
);

const expansions = [
  { key: "vanilla", name: "Vanilla", aliases: ["classic", "kalimdor", "eastern kingdoms"] },
  { key: "tbc", name: "The Burning Crusade", aliases: ["burning crusade", "outland"] },
  { key: "wrath", name: "Wrath of the Lich King", aliases: ["wrath", "lich king", "northrend"] },
  { key: "cataclysm", name: "Cataclysm", aliases: ["cataclysm"] },
  { key: "mop", name: "Mists of Pandaria", aliases: ["pandaria", "mists of pandaria"] },
  { key: "wod", name: "Warlords of Draenor", aliases: ["draenor", "warlords"] },
  { key: "legion", name: "Legion", aliases: ["legion", "broken isles"] },
  { key: "bfa", name: "Battle for Azeroth", aliases: ["battle for azeroth", "kul tiras", "zandalar"] },
  { key: "shadowlands", name: "Shadowlands", aliases: ["shadowlands"] },
  { key: "dragonflight", name: "Dragonflight", aliases: ["dragonflight", "dragon isles"] },
  { key: "warWithin", name: "The War Within", aliases: ["war within", "khaz algar"] },
  { key: "midnight", name: "Midnight", aliases: ["midnight"] },
];

const categoryLabels = {
  92: "General",
  96: "Quetes",
  97: "Exploration",
  95: "Joueur contre joueur",
  168: "Donjons et raids",
  169: "Metiers",
  201: "Reputation",
  155: "Evenements mondiaux",
  15117: "Combats de mascottes",
  15246: "Collections",
  15271: "Contenu d'extension",
  81: "Tours de force",
};

function normalize(value) {
  return String(value ?? "")
    .toLocaleLowerCase("fr-FR")
    .replace(/[’`]/g, "'")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");
}

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

async function loadJsonFile(filePath, fallback) {
  try {
    const content = await fs.readFile(filePath, "utf8");
    return JSON.parse(content);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
    return fallback;
  }
}

async function loadExistingEnrichedAchievements() {
  const data = await loadJsonFile(
    path.join(generatedDir, "achievements_catalog_enriched.json"),
    [],
  );

  return new Map(data.map((achievement) => [achievement.id, achievement]));
}

async function fetchAchievementDetails(achievements, token, existingById) {
  const enrichedAchievements = [];
  const failedIds = [];
  const concurrency = 4;
  let nextIndex = 0;

  async function fetchWithRetry(achievement) {
    const retries = 4;

    for (let attempt = 0; attempt <= retries; attempt += 1) {
      try {
        return await fetchBlizzardJson(
          `https://eu.api.blizzard.com/data/wow/achievement/${achievement.id}`,
          token,
        );
      } catch (error) {
        const status = error?.response?.status;

        if (status !== 429 || attempt === retries) {
          throw error;
        }

        await delay(700 * (attempt + 1));
      }
    }
  }

  async function worker() {
    while (nextIndex < achievements.length) {
      const index = nextIndex;
      nextIndex += 1;
      const achievement = achievements[index];
      const cached = existingById.get(achievement.id);

      if (cached?.name && cached?.categoryName) {
        enrichedAchievements.push(cached);
        continue;
      }

      try {
        await delay(80);
        const details = await fetchWithRetry(achievement);

        enrichedAchievements.push({
          id: details.id,
          name: details.name,
          description: details.description ?? "",
          points: details.points ?? 0,
          isAccountWide: details.is_account_wide ?? false,
          categoryId: details.category?.id ?? null,
          categoryName: details.category?.name ?? "",
          rewardDescription: details.reward_description ?? "",
          displayOrder: details.display_order ?? null,
          criteria: details.criteria ?? null,
          nextAchievementId: details.next_achievement?.id ?? null,
          previousAchievementId: details.previous_achievement?.id ?? null,
        });
      } catch (error) {
        failedIds.push(achievement.id);
        console.log(
          `ERREUR ACHIEVEMENT ID ${achievement.id}: ${error?.response?.status ?? error.message}`,
        );
        enrichedAchievements.push({
          id: achievement.id,
          name: achievement.name,
          description: "",
          points: 0,
          isAccountWide: false,
          categoryId: null,
          categoryName: "",
          rewardDescription: "",
          displayOrder: null,
          criteria: null,
          nextAchievementId: null,
          previousAchievementId: null,
        });
      }

      if ((index + 1) % 250 === 0) {
        console.log(`${index + 1}/${achievements.length} hauts faits Blizzard`);
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));

  enrichedAchievements.sort((a, b) => a.id - b.id);

  return { enrichedAchievements, failedIds };
}

function extractWowheadListviewData(html) {
  const listviewsMatch = html.match(
    /<script type="application\/json" id="data\.page\.listPage\.listviews">([\s\S]*?)<\/script>/,
  );

  if (listviewsMatch) {
    const listviews = JSON.parse(listviewsMatch[1]);
    const achievementsListview = listviews.find(
      (listview) => listview.id === "achievements",
    );

    return achievementsListview?.data ?? [];
  }

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

async function fetchWowheadAchievementIndex() {
  const byId = new Map();
  const fetchStats = [];
  const urls = ["https://www.wowhead.com/achievements"];

  for (const url of urls) {
    try {
      const response = await axios.get(url, {
        headers: {
          "User-Agent": "Mozilla/5.0 WoW100 metadata helper",
        },
        responseType: "text",
      });
      const rows = extractWowheadListviewData(response.data);

      fetchStats.push({ source: url, count: rows.length });

      for (const row of rows) {
        if (!row.id) continue;

        byId.set(row.id, {
          wowheadName: row.name,
          wowheadUrl: `https://www.wowhead.com/achievement=${row.id}`,
          category: row.category ?? null,
          categoryName: row.categoryName ?? row.category2 ?? "",
          expansion: row.expansion ?? null,
          points: row.points ?? null,
          reward: row.reward ?? "",
          popularity: row.popularity ?? null,
        });
      }
    } catch (error) {
      fetchStats.push({ source: url, error: error.message });
    }
  }

  return { byId, fetchStats };
}

async function loadManualMetadata() {
  const data = await loadJsonFile(metadataPath, []);
  return Object.fromEntries(data.map((item) => [item.blizzardId, item]));
}

function inferExpansion(achievement, manualMetadata, wowheadMetadata) {
  if (manualMetadata.expansion) {
    return manualMetadata.expansion;
  }

  const candidateText = normalize(
    [
      achievement.categoryName,
      wowheadMetadata?.categoryName,
      wowheadMetadata?.expansion,
      achievement.name,
      achievement.description,
    ].join(" "),
  );

  for (const expansion of expansions) {
    if (expansion.aliases.some((alias) => candidateText.includes(normalize(alias)))) {
      return expansion.key;
    }
  }

  return "allAchievements";
}

function inferGroup(achievement, manualMetadata, wowheadMetadata) {
  const manualGroup = firstNonEmpty(manualMetadata.instance, manualMetadata.category);

  if (manualGroup) return manualGroup;

  const categoryName = firstNonEmpty(
    achievement.categoryName,
    wowheadMetadata?.categoryName,
    categoryLabels[achievement.categoryId],
  );

  return categoryName || "A classer";
}

function toWow100Item(achievement, manualMetadata, wowheadMetadata) {
  const expansion = inferExpansion(achievement, manualMetadata, wowheadMetadata);
  const group = inferGroup(achievement, manualMetadata, wowheadMetadata);
  const source = firstNonEmpty(
    manualMetadata.source,
    achievement.description,
    achievement.rewardDescription,
    "Objectif a verifier",
  );
  const externalUrl = firstNonEmpty(
    manualMetadata.externalUrl,
    manualMetadata.mamytwink?.url,
    wowheadMetadata?.wowheadUrl,
    `https://www.wowhead.com/achievement=${achievement.id}`,
  );

  return {
    id: `achievement_${achievement.id}`,
    name: achievement.name,
    description: achievement.description,
    category: "achievements",
    expansion,
    zone: firstNonEmpty(manualMetadata.zone, group),
    instance: group,
    source,
    points: achievement.points,
    rewardDescription: achievement.rewardDescription,
    isAccountWide: achievement.isAccountWide,
    groupRequired: manualMetadata.groupRequired ?? normalize(group).includes("raid"),
    weeklyLockout: manualMetadata.weeklyLockout ?? false,
    blizzardId: achievement.id,
    wowheadAchievementId: achievement.id,
    boss: manualMetadata.boss ?? "",
    externalUrl,
    blizzardCategoryId: achievement.categoryId,
    blizzardCategoryName: achievement.categoryName,
    wowhead: wowheadMetadata ?? null,
    mamytwink: manualMetadata.mamytwink ?? null,
  };
}

async function main() {
  const token = await getToken();
  const catalog = await fetchBlizzardJson(
    "https://eu.api.blizzard.com/data/wow/achievement/index",
    token,
  );

  console.log(`Hauts faits Blizzard trouves : ${catalog.achievements.length}`);

  await fs.mkdir(generatedDir, { recursive: true });
  await fs.mkdir(achievementDataDir, { recursive: true });

  await fs.writeFile(
    path.join(generatedDir, "achievements_catalog_raw.json"),
    `${JSON.stringify(catalog, null, 2)}\n`,
    "utf8",
  );

  const existingEnriched = await loadExistingEnrichedAchievements();

  const [{ enrichedAchievements, failedIds }, wowhead, manualById] =
    await Promise.all([
      fetchAchievementDetails(catalog.achievements, token, existingEnriched),
      fetchWowheadAchievementIndex(),
      loadManualMetadata(),
    ]);

  await fs.writeFile(
    path.join(generatedDir, "achievements_catalog_enriched.json"),
    `${JSON.stringify(enrichedAchievements, null, 2)}\n`,
    "utf8",
  );

  await fs.writeFile(
    path.join(generatedDir, "achievements_wowhead_index.json"),
    `${JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        source: "https://www.wowhead.com/achievements",
        fetchStats: wowhead.fetchStats,
        achievements: Object.fromEntries([...wowhead.byId.entries()].sort()),
      },
      null,
      2,
    )}\n`,
    "utf8",
  );

  const wow100Draft = enrichedAchievements.map((achievement) =>
    toWow100Item(
      achievement,
      manualById[achievement.id] ?? {},
      wowhead.byId.get(achievement.id),
    ),
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
    path.join(generatedDir, "achievements_wow100_draft.json"),
    `${JSON.stringify(wow100Draft, null, 2)}\n`,
    "utf8",
  );

  for (const expansion of expansions) {
    const items = wow100Draft.filter(
      (achievement) => achievement.expansion === expansion.key,
    );

    await fs.writeFile(
      path.join(achievementDataDir, `${expansion.key}_achievements.json`),
      `${JSON.stringify(items, null, 2)}\n`,
      "utf8",
    );

    console.log(`${expansion.key}_achievements.json : ${items.length} hauts faits`);
  }

  const unclassified = wow100Draft.filter(
    (achievement) => achievement.expansion === "allAchievements",
  );

  console.log(
    JSON.stringify(
      {
        blizzardAchievements: catalog.achievements.length,
        enrichedAchievements: enrichedAchievements.length,
        failedIds,
        classifiedByMetadata: wow100Draft.length - unclassified.length,
        unclassified: unclassified.length,
        wowheadRows: wowhead.byId.size,
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
