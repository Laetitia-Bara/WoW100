import {
  handleOptions,
  json,
  readBattleNetResponse,
  requireEnv,
  toErrorResponse,
  validateRedirectUri,
} from "../_shared/battlenet.js";

export async function onRequest({request, env}) {
  if (request.method === "OPTIONS") return handleOptions();

  try {
    const url = new URL(request.url);
    const code = url.searchParams.get("code");
    const redirectUri = url.searchParams.get("redirectUri");

    if (!code || !redirectUri) {
      return json({error: "missing_parameters"}, {status: 400});
    }

    validateRedirectUri(env, redirectUri);

    const params = new URLSearchParams();
    params.set("grant_type", "authorization_code");
    params.set("code", code);
    params.set("redirect_uri", redirectUri);

    const credentials = `${requireEnv(env, "BATTLENET_CLIENT_ID")}:${requireEnv(
      env,
      "BATTLENET_CLIENT_SECRET",
    )}`;

    const result = await fetch("https://eu.battle.net/oauth/token", {
      method: "POST",
      headers: {
        "authorization": `Basic ${btoa(credentials)}`,
        "content-type": "application/x-www-form-urlencoded",
      },
      body: params,
    });

    return json(await readBattleNetResponse(result));
  } catch (error) {
    return toErrorResponse(error);
  }
}
