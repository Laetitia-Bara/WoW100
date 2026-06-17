# App Review Reply - 2026-06-17

Use this in the App Review conversation after uploading a new build that includes the legal text correction.

```text
Hello App Review Team,

Thank you for the additional details.

We identified a platform-specific wording issue in the app's in-app privacy/legal screen. One sentence referred to deleting local app data from "Android settings". This wording was not relevant to iOS users and has been revised in the new build to use platform-neutral wording: "device settings".

The app binary and metadata do not intentionally reference Google Play. WoW100% is an iOS app experience and the revised build removes the Android-specific wording that could have caused this misunderstanding.

Regarding the launch crash mentioned in the previous automated message, we have reviewed the iOS startup configuration and submitted a new build after validation. If the app still crashes during review, could you please provide the crash log, tested device model, and iOS version so we can investigate the exact failure path?

We also experienced an App Store Connect/TestFlight testing access issue while trying to validate this build with testers. We are handling that separately through Apple Developer Support, and we are resubmitting this corrected build for App Review.

Best regards,
Laetitia BARA
```

Resubmission checklist:

- Upload a new iOS build with an incremented build number.
- Select the new build in the App Store version before resubmitting.
- Replace the App Review notes with the updated text in `docs/apple-review-notes.md`.
- Attach or link a short iPhone screen recording if available.
- If TestFlight still cannot install for testers, open a separate Apple Developer Support ticket and reference that ticket ID in the review reply.
