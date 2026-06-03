import axios from "axios";
import dotenv from "dotenv";
import fs from "fs/promises";

dotenv.config();

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

async function main() {
  const token = await getToken();

  const catalog = await axios.get(
    "https://eu.api.blizzard.com/data/wow/mount/index",
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      params: {
        namespace: "static-eu",
        locale: "fr_FR",
      },
    },
  );

  console.log(`Montures trouvées : ${catalog.data.mounts.length}`);

  await fs.mkdir("../../assets/generated", {
    recursive: true,
  });

  await fs.writeFile(
    "../../assets/generated/mounts_catalog_raw.json",
    JSON.stringify(catalog.data, null, 2),
    "utf8",
  );

  console.log("Catalogue sauvegardé");

  const enrichedMounts = [];

  for (const mount of catalog.data.mounts) {
    try {
      const details = await axios.get(
        `https://eu.api.blizzard.com/data/wow/mount/${mount.id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "static-eu",
            locale: "fr_FR",
          },
        },
      );

      enrichedMounts.push({
        id: details.data.id,
        name: details.data.name,
        description: details.data.description ?? "",
        sourceType: details.data.source?.type ?? "",
        sourceName: details.data.source?.name ?? "",
        faction: details.data.faction?.name ?? "",
        requirements: details.data.requirements ?? null,
      });

      console.log(
        `${enrichedMounts.length}/${catalog.data.mounts.length} - ${details.data.name}`,
      );
    } catch (e) {
      console.log(`ERREUR ID ${mount.id}`);
    }
  }
  await fs.writeFile(
    "../../assets/generated/mounts_catalog_enriched.json",
    JSON.stringify(enrichedMounts, null, 2),
    "utf8",
  );

  console.log("Catalogue enrichi sauvegardé");

  const sourceTypes = [
    ...new Set(enrichedMounts.map((m) => m.sourceType).filter(Boolean)),
  ].sort();

  console.log(sourceTypes);

  const sourceStats = {};

  for (const mount of enrichedMounts) {
    const source = mount.sourceType || "UNKNOWN";
    sourceStats[source] = (sourceStats[source] ?? 0) + 1;
  }

  console.table(sourceStats);

  const sourceMap = {
    VENDOR: "Marchand",
    DROP: "Butin",
    ACHIEVEMENT: "Haut fait",
    PROFESSION: "Métier",
    QUEST: "Quête",
    WORLDEVENT: "Événement mondial",
    TRADINGPOST: "Comptoir",
    PETSTORE: "Boutique",
    TCG: "TCG",
    PROMOTION: "Promotion",
    DISCOVERY: "Découverte",
  };

  const wow100Draft = enrichedMounts.map((mount) => {
    return {
      id: `mount_${mount.id}`,
      name: mount.name,
      description: mount.description,
      category: "mounts",
      expansion: "vanilla",
      zone: "",
      instance: "",
      source: sourceMap[mount.sourceType] ?? "Inconnu",
      sourceType: mount.sourceType || "UNKNOWN",
      sourceName: mount.sourceName || "",
      faction: mount.faction || "",
      groupRequired: false,
      weeklyLockout: mount.sourceType === "DROP",
      blizzardId: mount.id,
    };
  });

  await fs.writeFile(
    "../../assets/generated/mounts_wow100_draft.json",
    JSON.stringify(wow100Draft, null, 2),
    "utf8",
  );

  console.log("Draft WoW100 sauvegardé");
}

main().catch(console.error);
