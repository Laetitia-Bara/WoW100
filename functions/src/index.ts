import * as dotenv from "dotenv";

dotenv.config();

import {onRequest} from "firebase-functions/v2/https";

export const testBattleNetConfig = onRequest(
  async (request, response) => {
    response.json({
      hasClientId: !!process.env.BATTLENET_CLIENT_ID,
      hasClientSecret: !!process.env.BATTLENET_CLIENT_SECRET,
    });
  }
);