# Account deletion Firestore audit

This note documents the Firestore paths touched by the in-app account deletion
flow. It is intentionally kept alongside the rules review so future changes do
not accidentally leave account-owned data behind.

## Deletion scope

For the authenticated Firebase UID, the app deletes:

- `users/{uid}/friends/*`
- `users/{uid}/settings/mainCharacter`
- `farmRoutes/*` where `ownerUid == uid`
- `farmProfiles/*` where `ownerUid == uid`
- `users/{uid}`
- the Firebase Authentication user record

Local preferences are cleared after the remote deletion succeeds. This removes
the Battle.net token, selected character, manual friends, planner progress and
remembered sign-in information from the device.

## Rule review

- A user can delete only `users/{uid}` where the path UID equals the current
  Firebase Auth UID.
- A user can delete only their own `users/{uid}/friends/*` and
  `users/{uid}/settings/mainCharacter` documents.
- Farm routes and farm profiles remain deletable only when their stored owner
  UID equals the current Firebase Auth UID.
- `farmProfiles` list access is restricted to an authenticated query whose
  returned documents belong to the current UID; arbitrary profiles are not
  listable by another user. Known profile documents remain readable for the
  existing friend-sharing flow.
- The existing create/update validation remains in place for every collection;
  the deletion change does not grant a user permission to edit another user's
  data or premium fields.

## Red-team checks

- Unauthenticated delete: denied by `isOwner` / `isAuthenticated`.
- Delete another user's profile or route: denied because the stored owner UID
  is compared with `request.auth.uid`.
- Query another user's farm profiles: denied because the list rule requires the
  returned document owner UID to match the caller; the deletion query includes
  `where('ownerUid', isEqualTo: uid)`.
- Escalate premium entitlement while deleting: impossible; the user document
  delete rule grants no update permission and the existing update rule keeps
  premium fields immutable.
- Batch/resource exhaustion: client batches are capped at 450 writes, below
  Firestore's 500-write limit. Existing per-document field and array limits
  remain active for writes.
