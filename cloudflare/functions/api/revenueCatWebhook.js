import {handleOptions, json, requireEnv, toErrorResponse} from "../_shared/battlenet.js";

const firestoreDatabase = "(default)";
let cachedGoogleAccessToken = null;

export async function onRequest({request, env}) {
  if (request.method === "OPTIONS") return handleOptions();

  try {
    if (request.method !== "POST") {
      return json({error: "method_not_allowed"}, {status: 405});
    }

    const expectedAuthorization = env.REVENUECAT_WEBHOOK_AUTHORIZATION?.trim();
    if (expectedAuthorization) {
      const authorization = request.headers.get("authorization")?.trim() ?? "";
      if (authorization !== expectedAuthorization) {
        return json({error: "unauthorized"}, {status: 401});
      }
    }

    const body = await request.json();
    const event = body?.event;
    if (!event || typeof event !== "object") {
      return json({error: "missing_event"}, {status: 400});
    }

    const status = premiumStatusFromWebhookEvent(env, event);
    if (status == null) {
      return json({
        ok: true,
        ignored: true,
        reason: "event_does_not_reference_premium_entitlement",
      });
    }

    const userIds = revenueCatUserCandidates(event);
    if (userIds.length === 0) {
      return json({error: "missing_app_user_id"}, {status: 400});
    }

    const updatedUsers = await syncPremiumStatusForUsers(env, userIds, status, event);

    return json({
      ok: true,
      isPremium: status.isPremium,
      updatedUsers,
    });
  } catch (error) {
    return toErrorResponse(error);
  }
}

function premiumStatusFromWebhookEvent(env, event) {
  const entitlementIds = revenueCatEntitlementIds(event);
  if (!hasPremiumEntitlement(env, entitlementIds)) {
    return null;
  }

  const expirationAt = dateFromMillis(event.expiration_at_ms);
  const type = event.type ?? "";
  const isExpiration = type === "EXPIRATION";
  const isPremium =
    !isExpiration && (expirationAt == null || expirationAt.getTime() > Date.now());

  return {
    isPremium,
    entitlementIds: isPremium ? entitlementIds : [],
    expirationAt,
    source: "revenuecat_webhook",
  };
}

function hasPremiumEntitlement(env, entitlementIds) {
  const identifiers = [
    env.REVENUECAT_PREMIUM_ENTITLEMENT_ID?.trim() || "WoW100% Premium",
    env.REVENUECAT_PREMIUM_ENTITLEMENT_REST_ID?.trim() || "ent1288ffbccce",
  ].filter(Boolean);

  return entitlementIds.some((entitlementId) => identifiers.includes(entitlementId));
}

function revenueCatEntitlementIds(event) {
  const ids = new Set();

  addString(ids, event.entitlement_id);
  if (Array.isArray(event.entitlement_ids)) {
    for (const entitlementId of event.entitlement_ids) {
      addString(ids, entitlementId);
    }
  }

  return [...ids];
}

function revenueCatUserCandidates(event) {
  const ids = new Set();

  addString(ids, event.app_user_id);
  addString(ids, event.original_app_user_id);

  if (Array.isArray(event.aliases)) {
    for (const alias of event.aliases) {
      addString(ids, alias);
    }
  }

  return [...ids];
}

function addString(ids, value) {
  if (typeof value !== "string") return;

  const trimmed = value.trim();
  if (trimmed) {
    ids.add(trimmed);
  }
}

function dateFromMillis(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    return null;
  }

  return new Date(value);
}

async function syncPremiumStatusForUsers(env, userIds, status, event) {
  const accessToken = await getGoogleAccessToken(env);
  const projectId = requireEnv(env, "FIREBASE_PROJECT_ID");
  const results = await Promise.all(
    userIds.map((userId) =>
      syncPremiumStatusForUser({env, projectId, accessToken, userId, status, event}),
    ),
  );

  return results.filter(Boolean).length;
}

async function syncPremiumStatusForUser({
  projectId,
  accessToken,
  userId,
  status,
  event,
}) {
  const documentPath = firestoreDocumentPath(projectId, userId);
  const existing = await fetch(documentPath, {
    headers: {authorization: `Bearer ${accessToken}`},
  });

  if (existing.status === 404) {
    return false;
  }

  if (!existing.ok) {
    await throwFirestoreError(existing);
  }

  const now = new Date().toISOString();
  const updateUrl = new URL(documentPath);
  for (const fieldPath of [
    "isPremium",
    "premiumSource",
    "premiumExpirationAt",
    "premiumEntitlements",
    "revenueCatAppUserId",
    "revenueCatManagementUrl",
    "revenueCatUpdatedAt",
    "updatedAt",
  ]) {
    updateUrl.searchParams.append("updateMask.fieldPaths", fieldPath);
  }

  const result = await fetch(updateUrl, {
    method: "PATCH",
    headers: {
      authorization: `Bearer ${accessToken}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      fields: {
        isPremium: {booleanValue: status.isPremium},
        premiumSource: {stringValue: status.source},
        premiumExpirationAt: firestoreNullableTimestamp(status.expirationAt),
        premiumEntitlements: firestoreStringArray(status.entitlementIds),
        revenueCatAppUserId: {stringValue: event.app_user_id ?? userId},
        revenueCatManagementUrl: {nullValue: "NULL_VALUE"},
        revenueCatUpdatedAt: {timestampValue: now},
        updatedAt: {timestampValue: now},
      },
    }),
  });

  if (!result.ok) {
    await throwFirestoreError(result);
  }

  return true;
}

function firestoreDocumentPath(projectId, userId) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${
    encodeURIComponent(firestoreDatabase)
  }/documents/users/${encodeURIComponent(userId)}`;
}

function firestoreNullableTimestamp(value) {
  if (value == null) {
    return {nullValue: "NULL_VALUE"};
  }

  return {timestampValue: value.toISOString()};
}

function firestoreStringArray(values) {
  return {
    arrayValue: {
      values: values.map((value) => ({stringValue: value})),
    },
  };
}

async function throwFirestoreError(result) {
  const text = await result.text();
  const error = new Error("Firestore request failed");
  error.status = result.status;
  error.data = text ? JSON.parse(text) : null;
  throw error;
}

async function getGoogleAccessToken(env) {
  const nowSeconds = Math.floor(Date.now() / 1000);
  if (cachedGoogleAccessToken && cachedGoogleAccessToken.expiresAt > nowSeconds + 60) {
    return cachedGoogleAccessToken.token;
  }

  const clientEmail = requireEnv(env, "FIREBASE_SERVICE_ACCOUNT_EMAIL");
  const privateKey = requireEnv(env, "FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY")
    .replaceAll("\\n", "\n");
  const assertion = await createGoogleJwt({clientEmail, privateKey, nowSeconds});

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    const error = new Error("Google OAuth token request failed");
    error.status = response.status;
    error.data = data;
    throw error;
  }

  cachedGoogleAccessToken = {
    token: data.access_token,
    expiresAt: nowSeconds + Math.max(0, Number(data.expires_in ?? 0)),
  };

  return cachedGoogleAccessToken.token;
}

async function createGoogleJwt({clientEmail, privateKey, nowSeconds}) {
  const header = {alg: "RS256", typ: "JWT"};
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  };
  const signingInput = `${base64UrlJson(header)}.${base64UrlJson(payload)}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    {name: "RSASSA-PKCS1-v1_5", hash: "SHA-256"},
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64Url(signature)}`;
}

function base64UrlJson(value) {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemToArrayBuffer(pem) {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  return bytes.buffer;
}

function base64Url(value) {
  const bytes = value instanceof ArrayBuffer ? new Uint8Array(value) : value;
  let binary = "";

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}
