# Firestore auth rules analysis

## Codebase findings

- Flutter app using Firebase Auth and Cloud Firestore.
- Firestore collection introduced by this change: `users/{uid}`.
- Firestore subcollection introduced by this follow-up: `users/{uid}/settings/mainCharacter`.
- Firestore subcollection introduced by the friends migration: `users/{uid}/friends/{friendId}`.
- App access pattern:
  - `users/{uid}` is read by the signed-in owner through a realtime stream.
  - `users/{uid}` is created on first Firebase sign-in.
  - `users/{uid}` is updated on later sign-ins to refresh identity fields.
  - `users/{uid}/settings/mainCharacter` is read on app start to restore the selected main character.
  - `users/{uid}/settings/mainCharacter` is created/updated when a user selects a Battle.net character.
  - `users/{uid}/friends` is read when opening the friends page.
  - `users/{uid}/friends/{friendId}` is created/updated when adding a friend manually or from the guild roster.
  - `users/{uid}/friends/{friendId}` is deleted when removing a friend.
  - The friends page migrates legacy `SharedPreferences` friends into Firestore once a Firebase user is signed in.
  - No collection-wide user list query is required.
- User document fields:
  - `uid`: string, required, immutable, must match auth uid.
  - `email`: string or null, optional private account data.
  - `displayName`: string or null, optional, max 80 chars.
  - `photoUrl`: URL string or null, optional, max 500 chars.
  - `providerIds`: list, optional, max 8 provider ids.
  - `isPremium`: bool, required, false on client create, immutable by client update.
  - `wallpaperPreference`: string, optional, one of `default`, `horde`, `alliance`.
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

## Friend document

- Document id: same value as `storageKey`, built from lowercase region, realm slug, and character name.
- `storageKey`: string, required, max 240, must match document id.
- `region`: string, required, max 8.
- `name`: string, required, max 80.
- `realm`: string, required, max 80.
- `realmSlug`: string, required, max 100.
- `level`: int, required, 0..1000.
- `race`: string, required, max 80.
- `characterClass`: string, required, max 80.
- `faction`: string, required, max 32.
- `guildName`: string or null, optional, max 100.
- `guildRealm`: string or null, optional, max 80.
- `guildRealmSlug`: string or null, optional, max 100.
- `achievementPoints`: int, required, 0..10000000.
- `portraitUrl`: URL string or null, optional, max 500.
- `updatedAt`: timestamp, required, must be request time.

## Devil's advocate checks

- Public list exploit: denied because every document path requires `request.auth != null` and owner uid.
- Unauthorized read/write: denied because document id must match `request.auth.uid`.
- Update bypass: denied because update calls the same profile validator and restricts immutable fields.
- Ownership hijacking: denied because `uid` must match the document id and auth uid, and cannot change.
- Resource exhaustion: string fields and provider list have size limits.
- Privilege escalation: denied because `isPremium` must be false on client create and unchanged on client update.
- Wallpaper preference abuse: constrained to three known values and owner-only updates.
- Schema pollution: denied by `hasOnly`.
- Required field omission: denied by `hasAll`.
- Query mismatch: no list query is required by the app.
- Main-character tampering: scoped under the owner uid and validates field names, field types, string lengths, numeric ranges, URL format, and update timestamp.
- Friends public list exploit: denied because `users/{uid}/friends` requires owner auth.
- Friends unauthorized read/write: denied because `isOwner(userId)` must match the parent user id.
- Friends update bypass: denied because create and update both call `hasValidFriendShape`.
- Friends ownership hijacking: denied because `storageKey` must match `{friendId}` and the path is under the owner's uid.
- Friends resource exhaustion: denied with max sizes for every string and URL field.
- Friends schema pollution: denied by `hasOnly`.
- Friends required field omission: denied by `hasAll`.
- Friends timestamp manipulation: denied because `updatedAt` must equal `request.time`.
