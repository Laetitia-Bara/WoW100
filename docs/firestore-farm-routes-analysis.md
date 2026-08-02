# Firestore farm routes analysis

## Existing Firestore paths

- `users/{uid}`: private user profile, read/write by owner only.
- `users/{uid}/settings/mainCharacter`: selected character, read/write by owner only.
- `users/{uid}/friends/{friendId}`: saved Battle.net friends, read/write by owner only.

## New Firestore path

- `farmRoutes/{routeId}`: saved farm route.
- `farmProfiles/{ownerStorageKey}`: public farm profile for a character, used by friends to select "Tous ses items".

## Route fields

- `ownerUid`: Firebase Auth uid. Required, immutable, must equal the writer.
- `ownerStorageKey`: public Battle.net character key used to find a friend's public routes.
- `ownerCharacterName`, `ownerRealm`, `ownerRealmSlug`, `ownerRegion`: denormalized public identity for saved route display.
- `name`: route name, 1 to 80 characters.
- `visibility`: `private` or `public`.
- `itemIds`: selected catalog item ids, 1 to 250 values.
- `createdAt`: server timestamp, immutable.
- `updatedAt`: server timestamp.

## Queries

- Current user's saved routes: `farmRoutes.where('ownerUid', isEqualTo: uid)`.
- Friend public routes: `farmRoutes.where('ownerStorageKey', isEqualTo: friend.storageKey).where('visibility', isEqualTo: 'public')`.
- Friend public wishlist profile: `farmProfiles.doc(friend.storageKey).get()`.

## Access assumptions

- Private routes are only readable by their owner.
- Public routes are readable by authenticated users so friends can discover them by Battle.net character key.
- Public farm profiles are readable by direct document lookup for authenticated users, but listing all profiles is denied.
- Writes remain owner-only and validated against strict field names, string lengths, enum values, and timestamps.

## Farm profile fields

- `ownerUid`: Firebase Auth uid. Required, immutable, must equal the writer.
- `ownerStorageKey`: Battle.net character storage key. Required, immutable, must match the document id.
- `ownerCharacterName`, `ownerRealm`, `ownerRealmSlug`, `ownerRegion`, `portraitUrl`: public character display fields.
- `itemIds`: public wishlist item ids, 0 to 1000 values.
- `updatedAt`: server timestamp.
