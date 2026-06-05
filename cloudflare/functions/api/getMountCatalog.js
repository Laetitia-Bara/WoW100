import {
  fetchBattleNetJson,
  getBattleNetServerToken,
  handleOptions,
  toErrorResponse,
  json,
} from "../_shared/battlenet.js";

export async function onRequest({request, env}) {
  if (request.method === "OPTIONS") return handleOptions();

  try {
    const token = await getBattleNetServerToken(env);
    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/data/wow/mount/index",
      {
        token,
        params: {
          namespace: "static-eu",
          locale: "fr_FR",
        },
      },
    );

    return json(data);
  } catch (error) {
    return toErrorResponse(error);
  }
}
