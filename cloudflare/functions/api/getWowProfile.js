import {
  characterProfileExists,
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

    const accounts = await Promise.all(
      (data.wow_accounts ?? []).map(async (account) => {
        const characters = await Promise.all(
          (account.characters ?? []).map(async (character) => {
            return (await characterProfileExists(token, character))
              ? character
              : null;
          }),
        );

        return {
          ...account,
          characters: characters.filter(Boolean),
        };
      }),
    );

    return json({...data, wow_accounts: accounts});
  } catch (error) {
    return toErrorResponse(error);
  }
}
