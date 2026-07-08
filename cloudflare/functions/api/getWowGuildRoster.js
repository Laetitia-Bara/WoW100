import {
  fetchBattleNetJson,
  getBearerToken,
  handleOptions,
  json,
  toErrorResponse,
} from "../_shared/battlenet.js";

export async function onRequest({request}) {
  if (request.method === "OPTIONS") return handleOptions();

  try {
    const url = new URL(request.url);
    const token = getBearerToken(request);
    const region = normalizeRegion(url.searchParams.get("region"));
    const realmSlug = slugify(url.searchParams.get("realmSlug"));
    const guildSlug = slugify(url.searchParams.get("guildName"));

    if (!token || !region || !realmSlug || !guildSlug) {
      return json({error: "missing_parameters"}, {status: 400});
    }

    const data = await fetchBattleNetJson(
      `https://${region}.api.blizzard.com/data/wow/guild/${realmSlug}/${guildSlug}/roster`,
      {
        token,
        params: {
          namespace: `profile-${region}`,
          locale: localeForRegion(region),
        },
      },
    );

    const members = Array.isArray(data.members) ? data.members : [];
    const guildName = data.guild?.name ?? url.searchParams.get("guildName");
    const guildRealm = data.guild?.realm?.name ?? "";
    const guildRealmSlug = data.guild?.realm?.slug ?? realmSlug;

    return json(
      members
        .map((entry) =>
          toGuildMemberSummary(
            entry,
            region,
            guildName,
            guildRealm,
            guildRealmSlug,
          ),
        )
        .filter((entry) => entry.name && entry.realmSlug),
    );
  } catch (error) {
    return toErrorResponse(error);
  }
}

function toGuildMemberSummary(
  entry,
  region,
  guildName,
  guildRealm,
  guildRealmSlug,
) {
  const character = entry.character ?? {};

  return {
    region: region.toUpperCase(),
    name: character.name ?? "",
    level: character.level ?? 0,
    realm: character.realm?.name ?? guildRealm,
    realmSlug: character.realm?.slug ?? guildRealmSlug,
    race: character.playable_race?.name ?? "",
    characterClass: character.playable_class?.name ?? "",
    faction: "",
    guildName,
    guildRealm,
    guildRealmSlug,
    achievementPoints: 0,
    portraitUrl: null,
  };
}

function normalizeRegion(value) {
  const region = (value ?? "eu").trim().toLowerCase();
  const allowedRegions = new Set(["eu", "us", "kr", "tw"]);

  return allowedRegions.has(region) ? region : null;
}

function localeForRegion(region) {
  switch (region) {
    case "us":
      return "en_US";
    case "kr":
      return "ko_KR";
    case "tw":
      return "zh_TW";
    default:
      return "fr_FR";
  }
}

function slugify(value) {
  return (value ?? "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/['’]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
