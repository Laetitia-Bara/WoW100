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