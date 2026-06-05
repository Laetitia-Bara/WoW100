const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers": "authorization, content-type",
};

export function handleOptions() {
  return new Response(null, {status: 204, headers: jsonHeaders});
}

export function json(data, init = {}) {
  return new Response(JSON.stringify(data), {
    ...init,
    headers: {
      ...jsonHeaders,
      ...(init.headers ?? {}),
    },
  });
}

export function getBearerToken(request) {
  const authorization = request.headers.get("authorization") ?? "";

  if (authorization.toLowerCase().startsWith("bearer ")) {
    return authorization.slice(7).trim();
  }

  return new URL(request.url).searchParams.get("token") ?? "";
}

export function requireEnv(env, key) {
  const value = env[key];

  if (!value) {
    throw new Error(`Missing Cloudflare secret: ${key}`);
  }

  return value;
}

export async function getBattleNetServerToken(env) {
  const params = new URLSearchParams();
  params.set("grant_type", "client_credentials");

  const result = await fetch("https://eu.battle.net/oauth/token", {
    method: "POST",
    headers: {
      "authorization": basicAuth(env),
      "content-type": "application/x-www-form-urlencoded",
    },
    body: params,
  });

  return readBattleNetResponse(result).then((data) => data.access_token);
}

export async function fetchBattleNetJson(path, {token, params = {}} = {}) {
  const url = new URL(path);

  for (const [key, value] of Object.entries(params)) {
    if (value != null && value !== "") {
      url.searchParams.set(key, value);
    }
  }

  const result = await fetch(url, {
    headers: {
      "authorization": `Bearer ${token}`,
    },
  });

  return readBattleNetResponse(result);
}

export async function readBattleNetResponse(result) {
  const text = await result.text();
  let data;

  try {
    data = text ? JSON.parse(text) : {};
  } catch (_) {
    data = {message: text};
  }

  if (!result.ok) {
    const error = new Error("Battle.net request failed");
    error.status = result.status;
    error.data = data;
    throw error;
  }

  return data;
}

export function validateRedirectUri(env, redirectUri) {
  const allowed = (env.BATTLENET_ALLOWED_REDIRECT_URIS ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);

  if (allowed.length === 0) {
    return;
  }

  if (!allowed.includes(redirectUri)) {
    const error = new Error("Redirect URI is not allowed");
    error.status = 400;
    error.data = {error: "invalid_redirect_uri"};
    throw error;
  }
}

export function toErrorResponse(error) {
  return json(
    {
      status: error.status ?? 500,
      data: error.data ?? null,
      message: error.message ?? String(error),
    },
    {status: error.status ?? 500},
  );
}

function basicAuth(env) {
  const clientId = requireEnv(env, "BATTLENET_CLIENT_ID");
  const clientSecret = requireEnv(env, "BATTLENET_CLIENT_SECRET");
  const credentials = `${clientId}:${clientSecret}`;

  return `Basic ${btoa(credentials)}`;
}
