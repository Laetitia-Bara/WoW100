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
    const token = getBearerToken(request);

    if (!token) {
      return json({error: "missing_token"}, {status: 400});
    }

    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/profile/user/wow",
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    const accounts = data.wow_accounts ?? [];
    const characterSummaries = [];

    for (const account of accounts) {
      const characters = account.characters ?? [];

      for (const character of characters) {
        characterSummaries.push({
          name: character.name,
          level: character.level,
          realm: character.realm?.name,
          race: character.playable_race?.name,
          characterClass: character.playable_class?.name,
          faction: character.faction?.name,
          realmSlug: character.realm?.slug,
        });
      }
    }

    const finalCharacters = await Promise.all(
      characterSummaries.map(async (character) => {
        const [
          professions,
          profile,
          portraitUrl,
          mythicKeystoneRating,
        ] = await Promise.all([
          fetchCharacterProfessions(token, character),
          fetchCharacterProfile(token, character),
          fetchCharacterPortraitUrl(token, character),
          fetchCharacterMythicKeystoneRating(token, character),
        ]);

        return {
          ...character,
          professions,
          achievementPoints: profile.achievement_points ?? 0,
          mythicKeystoneRating,
          portraitUrl,
        };
      }),
    );

    finalCharacters.sort((a, b) => b.level - a.level);

    return json(finalCharacters);
  } catch (error) {
    return toErrorResponse(error);
  }
}

async function fetchCharacterMythicKeystoneRating(token, character) {
  if (!character.realmSlug || !character.name) {
    return 0;
  }

  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/mythic-keystone-profile`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    return ratingFromMythicKeystoneProfile(data);
  } catch (_) {
    return 0;
  }
}

async function fetchCharacterProfile(token, character) {
  if (!character.realmSlug || !character.name) {
    return {};
  }

  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());

    return await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );
  } catch (_) {
    return {};
  }
}

async function fetchCharacterPortraitUrl(token, character) {
  if (!character.realmSlug || !character.name) {
    return null;
  }

  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/character-media`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    return pickCharacterPortraitUrl(data);
  } catch (_) {
    return null;
  }
}

async function fetchCharacterProfessions(token, character) {
  if (!character.realmSlug || !character.name) {
    return [];
  }

  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/professions`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    return collectProfessionNames(data);
  } catch (_) {
    return [];
  }
}

function collectProfessionNames(data) {
  const names = new Set();
  const entries = [
    ...(Array.isArray(data?.primaries) ? data.primaries : []),
    ...(Array.isArray(data?.secondaries) ? data.secondaries : []),
    ...(Array.isArray(data?.professions) ? data.professions : []),
  ];

  for (const entry of entries) {
    addProfessionName(names, entry);
  }

  return [...names];
}

function addProfessionName(names, value) {
  if (!value) return;

  if (typeof value === "string") {
    const name = value.trim();
    if (name) names.add(name);
    return;
  }

  if (typeof value !== "object") return;

  addProfessionName(names, value.profession);
  addProfessionName(names, value.name);
}

function ratingFromMythicKeystoneProfile(profile) {
  const rating = profile?.current_mythic_rating?.rating;

  if (typeof rating === "number") {
    return Math.round(rating);
  }

  if (typeof rating === "string") {
    const parsed = Number.parseFloat(rating);
    return Number.isFinite(parsed) ? Math.round(parsed) : 0;
  }

  return 0;
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
