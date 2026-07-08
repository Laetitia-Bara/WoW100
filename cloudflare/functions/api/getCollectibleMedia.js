import {
  fetchBattleNetJson,
  getBattleNetServerToken,
  handleOptions,
  json,
  toErrorResponse,
} from "../_shared/battlenet.js";

const namespace = "static-eu";
const locale = "fr_FR";

export async function onRequest({request, env}) {
  if (request.method === "OPTIONS") return handleOptions();

  try {
    const url = new URL(request.url);
    const type = url.searchParams.get("type");
    const id = url.searchParams.get("id");

    if (!type || !id) {
      return json({error: "missing_type_or_id"}, {status: 400});
    }

    if (!/^\d+$/.test(id)) {
      return json({error: "invalid_id"}, {status: 400});
    }

    const token = await getBattleNetServerToken(env);
    const mediaUrl = await getMediaUrl({type, id, token});

    return json(
      {url: mediaUrl},
      {
        headers: {
          "cache-control": "public, max-age=86400",
        },
      },
    );
  } catch (error) {
    return toErrorResponse(error);
  }
}

async function getMediaUrl({type, id, token}) {
  if (type === "mount") {
    return getMountMediaUrl({id, token});
  }

  if (type === "pet") {
    return getPetMediaUrl({id, token});
  }

  return null;
}

async function getMountMediaUrl({id, token}) {
  const mount = await fetchBattleNetJson(
    `https://eu.api.blizzard.com/data/wow/mount/${id}`,
    {
      token,
      params: {namespace, locale},
    },
  );

  const displays = Array.isArray(mount.creature_displays)
    ? mount.creature_displays
    : [];

  for (const display of displays) {
    const media = await getLinkedMedia({
      token,
      href: display.key?.href,
      fallbackPath: display.id
        ? `https://eu.api.blizzard.com/data/wow/media/creature-display/${display.id}`
        : "",
    });
    const mediaUrl = pickMediaUrl(media);

    if (mediaUrl) return mediaUrl;
  }

  return null;
}

async function getPetMediaUrl({id, token}) {
  const directMedia = await tryFetchBattleNetJson(
    `https://eu.api.blizzard.com/data/wow/media/pet/${id}`,
    {
      token,
      params: {namespace, locale},
    },
  );
  const directMediaUrl = pickMediaUrl(directMedia);

  if (directMediaUrl) return directMediaUrl;

  const pet = await tryFetchBattleNetJson(
    `https://eu.api.blizzard.com/data/wow/pet/${id}`,
    {
      token,
      params: {namespace, locale},
    },
  );

  const linkedMedia = await getLinkedMedia({
    token,
    href: pet?.media?.key?.href,
  });

  return pickMediaUrl(linkedMedia);
}

async function getLinkedMedia({token, href, fallbackPath = ""}) {
  const path = href || fallbackPath;

  if (!path) return null;

  return tryFetchBattleNetJson(path, {
    token,
    params: {namespace, locale},
  });
}

async function tryFetchBattleNetJson(path, options) {
  try {
    return await fetchBattleNetJson(path, options);
  } catch (_) {
    return null;
  }
}

function pickMediaUrl(media) {
  const assets = Array.isArray(media?.assets) ? media.assets : [];
  const preferred =
    assets.find((asset) => asset.key === "zoom") ??
    assets.find((asset) => asset.key === "main") ??
    assets.find((asset) => asset.key === "default") ??
    assets.find((asset) => typeof asset.value === "string");

  return preferred?.value ?? null;
}
