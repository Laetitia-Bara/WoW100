import {
  fetchBattleNetJson,
  getBattleNetServerToken,
  handleOptions,
  json,
  toErrorResponse,
} from "../_shared/battlenet.js";

export async function onRequest({request, env}) {
  if (request.method === "OPTIONS") return handleOptions();

  try {
    const id = new URL(request.url).searchParams.get("id");

    if (!id) {
      return json({error: "missing_id"}, {status: 400});
    }

    const token = await getBattleNetServerToken(env);
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/data/wow/mount/${id}`,
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
