# Premium subscriptions with RevenueCat

This app removes mobile ads and web sponsor panels when `users/{uid}.isPremium`
is `true`. RevenueCat is the source of truth for Apple, Google Play, and web
Stripe purchases.

## Identifiers

- Entitlement identifier: `WoW100% Premium`
- Entitlement REST API identifier: `ent1288ffbccce`
- Offering: use RevenueCat current offering, or pass `REVENUECAT_OFFERING_ID`
- Products already attached in RevenueCat:
  - Google Play: `wow100_premium_monthly:p1m`
  - Apple: `WoW100_Premium`
  - Web / Stripe: `WoW100_Premium_Web`

Keep every Apple, Google, and Stripe product attached to the same entitlement.

## App build configuration

The public RevenueCat SDK keys are already configured in `AppConfig`:

- Android: `goog_RaZXGplgnynlCktWxZDxnzkxUdF`
- iOS: `appl_EHCttKWnNCpzwlPthKryIbXDOlh`
- Web: `rcb_OzPMcxuEYzjMZTUYsEwQLRiXrqiV`

They can still be overridden at build time:

```bash
flutter build appbundle \
  --dart-define=REVENUECAT_ANDROID_API_KEY=goog_... \
  "--dart-define=REVENUECAT_PREMIUM_ENTITLEMENT_ID=WoW100% Premium"

flutter build ios \
  --dart-define=REVENUECAT_IOS_API_KEY=appl_... \
  "--dart-define=REVENUECAT_PREMIUM_ENTITLEMENT_ID=WoW100% Premium"

flutter build web \
  --dart-define=REVENUECAT_WEB_API_KEY=web_... \
  "--dart-define=REVENUECAT_PREMIUM_ENTITLEMENT_ID=WoW100% Premium"
```

For a non-current offering, also pass:

```bash
--dart-define=REVENUECAT_OFFERING_ID=<offering_id>
```

## Cloudflare webhook configuration

RevenueCat webhooks are handled by Cloudflare Pages Functions, so no Firebase
Blaze plan is required.

Webhook URL:

```text
https://wow100.cosmos-lty.fr/api/revenueCatWebhook
```

Equivalent Pages URL:

```text
https://wow100.pages.dev/api/revenueCatWebhook
```

In RevenueCat, the Authorization header can stay empty. If you later want to
protect it with a shared secret, set the same value in Cloudflare as
`REVENUECAT_WEBHOOK_AUTHORIZATION`.

Set these Cloudflare Pages secrets from the `cloudflare/` folder:

```bash
npx wrangler pages secret put FIREBASE_PROJECT_ID --project-name wow100
npx wrangler pages secret put FIREBASE_SERVICE_ACCOUNT_EMAIL --project-name wow100
npx wrangler pages secret put FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY --project-name wow100
```

Use:

```text
FIREBASE_PROJECT_ID=wow100-106c3
```

For the service account, create or reuse a Firebase/Google Cloud service account
with Firestore write access. Paste the `client_email` into
`FIREBASE_SERVICE_ACCOUNT_EMAIL`, and paste the full private key, including the
`-----BEGIN PRIVATE KEY-----` / `-----END PRIVATE KEY-----` lines, into
`FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY`.

Optional Cloudflare variables:

- `REVENUECAT_PREMIUM_ENTITLEMENT_ID`, defaults to `WoW100% Premium`
- `REVENUECAT_PREMIUM_ENTITLEMENT_REST_ID`, defaults to `ent1288ffbccce`

## Store setup checklist

1. Google Play Console: create a subscription product, add a base plan, publish
   it to an internal or closed testing track, and add testers.
2. App Store Connect: create the matching auto-renewable subscription, add it to
   a subscription group, and enable In-App Purchase capability in Xcode before
   the archive build.
3. Stripe: create one recurring flat-rate product/price, connect Stripe to
   RevenueCat, import the product, and attach it to the `WoW100% Premium`
   entitlement.
4. RevenueCat: create Apple, Google, and Web apps, map every product to
   `WoW100% Premium`, create an offering, and add the Firebase webhook.
5. Test with sandbox purchases, then confirm `users/{uid}.isPremium` flips to
   `true` and ads/sponsors disappear.
