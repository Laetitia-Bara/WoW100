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
    const characterName = url.searchParams.get("characterName")?.trim() ?? "";

    if (!token || !region || !realmSlug || !characterName) {
      return json({error: "missing_parameters"}, {status: 400});
    }

    const characterSlug = encodeURIComponent(characterName.toLowerCase());
    const params = {
      namespace: `profile-${region}`,
      locale: localeForRegion(region),
    };

    const [profile, portraitUrl] = await Promise.all([
      fetchBattleNetJson(
        `https://${region}.api.blizzard.com/profile/wow/character/${realmSlug}/${characterSlug}`,
        {token, params},
      ),
      fetchCharacterPortraitUrl(token, region, realmSlug, characterSlug, params),
    ]);

    return json(toCharacterSummary(profile, region, portraitUrl));
  } catch (error) {
    return toErrorResponse(error);
  }
}

async function fetchCharacterPortraitUrl(
  token,
  region,
  realmSlug,
  characterSlug,
  params,
) {
  try {
    const media = await fetchBattleNetJson(
      `https://${region}.api.blizzard.com/profile/wow/character/${realmSlug}/${characterSlug}/character-media`,
      {token, params},
    );

    return pickCharacterPortraitUrl(media);
  } catch (_) {
    return null;
  }
}

function toCharacterSummary(profile, region, portraitUrl) {
  return {
    region: region.toUpperCase(),
    name: profile.name ?? "",
    level: profile.level ?? 0,
    realm: profile.realm?.name ?? "",
    realmSlug: profile.realm?.slug ?? "",
    race: profile.playable_race?.name ?? "",
    characterClass: profile.playable_class?.name ?? "",
    faction: profile.faction?.name ?? "",
    guildName: profile.guild?.name ?? null,
    guildRealm: profile.guild?.realm?.name ?? null,
    guildRealmSlug: profile.guild?.realm?.slug ?? null,
    achievementPoints: profile.achievement_points ?? 0,
    portraitUrl,
  };
}

function pickCharacterPortraitUrl(media) {
  const assets = Array.isArray(media?.assets) ? media.assets : [];
  const preferred =
    assets.find((asset) => asset.key === "inset") ??
    assets.find((asset) => asset.key === "avatar") ??
    assets.find((asset) => asset.key === "main-raw") ??
    assets.find((asset) => asset.key === "main") ??
    assets.find((asset) => typeof asset.value === "string");

  return preferred?.value ?? null;
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
