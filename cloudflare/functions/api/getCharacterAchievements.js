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
    const realmSlug = url.searchParams.get("realmSlug");
    const characterName = url.searchParams.get("characterName");

    if (!token || !realmSlug || !characterName) {
      return json({error: "missing_parameters"}, {status: 400});
    }

    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${realmSlug}/${characterName.toLowerCase()}/achievements`,
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
