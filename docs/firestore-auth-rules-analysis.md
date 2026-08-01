# Firestore auth rules analysis

## Codebase findings

- Flutter app using Firebase Auth and Cloud Firestore.
- Firestore collection introduced by this change: `users/{uid}`.
- Firestore subcollection introduced by this follow-up: `users/{uid}/settings/mainCharacter`.
- App access pattern:
  - `users/{uid}` is read by the signed-in owner through a realtime stream.
  - `users/{uid}` is created on first Firebase sign-in.
  - `users/{uid}` is updated on later sign-ins to refresh identity fields.
  - `users/{uid}/settings/mainCharacter` is read on app start to restore the selected main character.
  - `users/{uid}/settings/mainCharacter` is created/updated when a user selects a Battle.net character.
  - No collection-wide user list query is required.
- User document fields:
  - `uid`: string, required, immutable, must match auth uid.
  - `email`: string or null, optional private account data.
  - `displayName`: string or null, optional, max 80 chars.
  - `photoUrl`: URL string or null, optional, max 500 chars.
  - `providerIds`: list, optional, max 8 provider ids.
  - `isPremium`: bool, required, false on client create, immutable by client update.
  - `createdAt`: timestamp, required, immutable.
  - `updatedAt`: timestamp, required.
  - Security assumption:
  - Premium entitlement is not granted by the client. It must be written by a trusted server, Firebase Admin SDK, Cloud Function, or subscription webhook that bypasses client rules.

## Main character document

- `name`: string, required, max 80.
- `level`: int, required, 1..1000.
- `realm`: string, required, max 80.
- `race`: string, required, max 80.
- `characterClass`: string, required, max 80.
- `faction`: string, required, max 32.
- `realmSlug`: string, required, max 100.
- `achievementPoints`: int, required, 0..10000000.
- `portraitUrl`: URL string or null, optional, max 500.
- `updatedAt`: timestamp, required.

## Devil's advocate checks

- Public list exploit: denied because every document path requires `request.auth != null` and owner uid.
- Unauthorized read/write: denied because document id must match `request.auth.uid`.
- Update bypass: denied because update calls the same profile validator and restricts immutable fields.
- Ownership hijacking: denied because `uid` must match the document id and auth uid, and cannot change.
- Resource exhaustion: string fields and provider list have size limits.
- Privilege escalation: denied because `isPremium` must be false on client create and unchanged on client update.
- Schema pollution: denied by `hasOnly`.
- Required field omission: denied by `hasAll`.
- Query mismatch: no list query is required by the app.
- Main-character tampering: scoped under the owner uid and validates field names, field types, string lengths, numeric ranges, URL format, and update timestamp.
