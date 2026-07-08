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
      "https://eu.api.blizzard.com/profile/user/wow/collections/pets",
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    return json(data);
  } catch (error) {
    return toErrorResponse(error);
  }
}
