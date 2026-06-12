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
      characterSummaries.map(async (character) => ({
        ...character,
        professions: await fetchCharacterProfessions(token, character),
      })),
    );

    finalCharacters.sort((a, b) => b.level - a.level);

    return json(finalCharacters);
  } catch (error) {
    return toErrorResponse(error);
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

    const entries = [
      ...(data.primaries ?? []),
      ...(data.secondaries ?? []),
    ];

    return [
      ...new Set(
        entries
          .map((entry) => entry.profession?.name)
          .filter(Boolean),
      ),
    ];
  } catch (_) {
    return [];
  }
}
