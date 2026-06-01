import * as dotenv from "dotenv";
dotenv.config();

import axios from "axios";
import {onRequest} from "firebase-functions/v2/https";

export const exchangeBattleNetCode = onRequest(
  async (request, response) => {
    try {
      const code = request.query.code as string;

      if (!code) {
        response.status(400).json({
          error: "missing_code",
        });
        return;
      }

      const params = new URLSearchParams();

      params.append("grant_type", "authorization_code");
      params.append("code", code);
      params.append(
        "redirect_uri",
        "http://localhost:8080/callback",
      );

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

      const finalCharacters: any[] = [];

      for (const account of accounts) {
        const characters = account.characters ?? [];

        for (const character of characters) {
          finalCharacters.push({
            name: character.name,
            level: character.level,
            realm: character.realm?.name,
            race: character.playable_race?.name,
            characterClass: character.playable_class?.name,
            faction: character.faction?.name,
          });
        }
      }

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