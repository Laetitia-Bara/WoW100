import * as dotenv from "dotenv";
dotenv.config();

import axios from "axios";
import {onRequest} from "firebase-functions/v2/https";

async function getBattleNetServerToken(): Promise<string> {
  const params = new URLSearchParams();
  params.append("grant_type", "client_credentials");

  const result = await axios.post(
    "https://eu.battle.net/oauth/token",
    params,
    {
      auth: {
        username: process.env.BATTLENET_CLIENT_ID!,
        password: process.env.BATTLENET_CLIENT_SECRET!,
      },
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    },
  );

  return result.data.access_token;
}

async function fetchCharacterProfessions(
  token: string,
  character: {name?: string; realmSlug?: string},
): Promise<string[]> {
  if (!character.realmSlug || !character.name) {
    return [];
  }

  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const result = await axios.get(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/professions`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    return collectProfessionNames(result.data);
  } catch (_) {
    return [];
  }
}

function collectProfessionNames(data: any): string[] {
  const names = new Set<string>();
  const entries = [
    ...(Array.isArray(data?.primaries) ? data.primaries : []),
    ...(Array.isArray(data?.secondaries) ? data.secondaries : []),
    ...(Array.isArray(data?.professions) ? data.professions : []),
  ];

  for (const entry of entries) {
    addProfessionName(names, entry);
  }

  return [...names];
}

function addProfessionName(names: Set<string>, value: any): void {
  if (!value) return;

  if (typeof value === "string") {
    const name = value.trim();
    if (name) names.add(name);
    return;
  }

  if (typeof value !== "object") return;

  addProfessionName(names, value.profession);
  addProfessionName(names, value.name);
}

async function fetchCharacterProfile(
  token: string,
  character: {name?: string; realmSlug?: string},
): Promise<any> {
  if (!character.realmSlug || !character.name) {
    return {};
  }

  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const result = await axios.get(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    return result.data;
  } catch (_) {
    return {};
  }
}

async function fetchCharacterPortraitUrl(
  token: string,
  character: {name?: string; realmSlug?: string},
): Promise<string | null> {
  if (!character.realmSlug || !character.name) {
    return null;
  }

  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const result = await axios.get(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/character-media`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        params: {
          namespace: "profile-eu",
          locale: "fr_FR",
        },
      },
    );

    return pickCharacterPortraitUrl(result.data);
  } catch (_) {
    return null;
  }
}

function pickCharacterPortraitUrl(media: any): string | null {
  const assets = Array.isArray(media?.assets) ? media.assets : [];
  const preferred =
    assets.find((asset: any) => asset.key === "inset") ??
    assets.find((asset: any) => asset.key === "avatar") ??
    assets.find((asset: any) => asset.key === "main-raw") ??
    assets.find((asset: any) => asset.key === "main") ??
    assets.find((asset: any) => typeof asset.value === "string");

  return preferred?.value ?? null;
}

export const exchangeBattleNetCode = onRequest(
  async (request, response) => {
    try {
      const code = request.query.code as string;
      const redirectUri = request.query.redirectUri as string;

      if (!code || !redirectUri) {
        response.status(400).json({
          error: "missing_parameters",
        });
        return;
      }

      const params = new URLSearchParams();

      params.append("grant_type", "authorization_code");
      params.append("code", code);
      params.append("redirect_uri", redirectUri);

      const result = await axios.post(
        "https://eu.battle.net/oauth/token",
        params,
        {
          auth: {
            username: process.env.BATTLENET_CLIENT_ID!,
            password: process.env.BATTLENET_CLIENT_SECRET!,
          },
          headers: {
            "Content-Type":
              "application/x-www-form-urlencoded",
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
      response.status(500).json({
        error: e?.response?.data ?? e.toString(),
      });
    }
  }
);

export const getWowProfile = onRequest(
  async (request, response) => {
    try {
      const token = request.query.token as string;

      if (!token) {
        response.status(400).json({error: "missing_token"});
        return;
      }

      const result = await axios.get(
        "https://eu.api.blizzard.com/profile/user/wow",
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "profile-eu",
            locale: "fr_FR",
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
      response.status(500).json({
        error: e?.response?.data ?? e.toString(),
      });
    }
  }
);

export const getWowCharacters = onRequest(
  async (request, response) => {
    try {
      const token = request.query.token as string;

      if (!token) {
        response.status(400).json({
          error: "missing_token",
        });
        return;
      }

      const result = await axios.get(
        "https://eu.api.blizzard.com/profile/user/wow",
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "profile-eu",
            locale: "fr_FR",
          },
        },
      );

      const accounts = result.data.wow_accounts ?? [];

      const characterSummaries: any[] = [];

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
        characterSummaries.map(async (character) => {
          const [professions, profile, portraitUrl] = await Promise.all([
            fetchCharacterProfessions(token, character),
            fetchCharacterProfile(token, character),
            fetchCharacterPortraitUrl(token, character),
          ]);

          return {
            ...character,
            professions,
            achievementPoints: profile.achievement_points ?? 0,
            portraitUrl,
          };
        })
      );

      finalCharacters.sort((a, b) => b.level - a.level);

      response.json(finalCharacters);
    } catch (e: any) {
      response.status(500).json({
        error: e?.response?.data ?? e.toString(),
      });
    }
  }
);

export const getWowMounts = onRequest(
  async (request, response) => {
    try {
      const token = request.query.token as string;

      if (!token) {
        response.status(400).json({
          error: "missing_token",
        });
        return;
      }

      const result = await axios.get(
        "https://eu.api.blizzard.com/profile/user/wow/collections/mounts",
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "profile-eu",
            locale: "fr_FR",
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
      response.status(500).json({
        error: e?.response?.data ?? e.toString(),
      });
    }
  }
);

export const getWowPets = onRequest(
  async (request, response) => {
    try {
      const token = request.query.token as string;

      if (!token) {
        response.status(400).json({error: "missing_token"});
        return;
      }

      const result = await axios.get(
        "https://eu.api.blizzard.com/profile/user/wow/collections/pets",
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "profile-eu",
            locale: "fr_FR",
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
      response.status(500).json({
        error: e?.response?.data ?? e.toString(),
      });
    }
  }
);

export const getWowAchievements = onRequest(
  async (request, response) => {
    try {
      const token = request.query.token as string;

      const result = await axios.get(
        'https://eu.api.blizzard.com/profile/user/wow/collections/achievements',
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: 'profile-eu',
            locale: 'fr_FR',
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
  console.error("getWowAchievements error", {
    status: e?.response?.status,
    data: e?.response?.data,
    message: e?.message,
  });

  response.status(500).json({
    status: e?.response?.status ?? null,
    data: e?.response?.data ?? null,
    message: e?.message ?? String(e),
  });
}
  },
);

export const getCharacterAchievements = onRequest(
  async (request, response) => {
    try {
      const token = request.query.token as string;
      const realmSlug = request.query.realmSlug as string;
      const characterName = request.query.characterName as string;

      if (!token || !realmSlug || !characterName) {
        response.status(400).json({
          error: "missing_parameters",
        });
        return;
      }

      const result = await axios.get(
        `https://eu.api.blizzard.com/profile/wow/character/${realmSlug}/${characterName.toLowerCase()}/achievements`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "profile-eu",
            locale: "fr_FR",
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
      response.status(500).json({
        status: e?.response?.status ?? null,
        data: e?.response?.data ?? null,
        message: e?.message ?? String(e),
      });
    }
  }
);

export const getMountCatalog = onRequest(
  async (request, response) => {
    try {
      const token = await getBattleNetServerToken();

      const result = await axios.get(
        "https://eu.api.blizzard.com/data/wow/mount/index",
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "static-eu",
            locale: "fr_FR",
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
      response.status(500).json({
        status: e?.response?.status ?? null,
        data: e?.response?.data ?? null,
        message: e?.message ?? String(e),
      });
    }
  },
);

export const getMountDetails = onRequest(
  async (request, response) => {
    try {
      const id = request.query.id as string;

      if (!id) {
        response.status(400).json({
          error: "missing_id",
        });
        return;
      }

      const token = await getBattleNetServerToken();

      const result = await axios.get(
        `https://eu.api.blizzard.com/data/wow/mount/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          params: {
            namespace: "static-eu",
            locale: "fr_FR",
          },
        },
      );

      response.json(result.data);
    } catch (e: any) {
      response.status(500).json({
        status: e?.response?.status ?? null,
        data: e?.response?.data ?? null,
        message: e?.message ?? String(e),
      });
    }
  },
);
