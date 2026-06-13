# App Store Review Notes - WoW100%

Copy/paste this into App Store Connect > App Review Information > Notes, then replace the bracketed placeholders.

```text
Hello App Review Team,

Thank you for reviewing WoW100%. Please find below the requested information for this new app submission.

1. Screen recording
A screen recording captured on a physical iPhone running the latest available iOS version is available here:
[PASTE PRIVATE VIDEO LINK OR MENTION ATTACHMENT]

The recording starts with launching the app and demonstrates the main user flow:
- Opening WoW100%
- Viewing the World of Warcraft collection dashboard
- Filtering tracked categories: achievements, mounts, and pets
- Opening a collection planner by expansion/category
- Searching and filtering missing/available items
- Manually checking an item as obtained
- Opening an item reference link on Wowhead
- Connecting with Battle.net OAuth, if a review demo account is used
- Selecting a World of Warcraft character
- Returning to the dashboard with character and collection progress
- Disconnecting Battle.net, which clears the local access token and selected character
- Opening the legal and privacy information screen

The app does not include in-app purchases, subscriptions, paid content, user-generated content, public posting, messaging, account registration inside WoW100%, or App Tracking Transparency prompts.

2. Devices and operating systems tested
The app was tested before submission on:
- iPhone [MODEL], iOS [VERSION]
- iPhone [MODEL], iOS [VERSION]

3. App purpose and target audience
WoW100% is an independent collection companion for World of Warcraft players. It helps players track their progress across expansions for achievements, mounts, and battle pets. The app is intended for players who want a clear mobile checklist and progress dashboard for long-term collection goals.

The value of the app is to organize collection progress by expansion and category, highlight obtainable versus unavailable items, allow manual tracking, and optionally compare the user's progress with their Battle.net World of Warcraft profile after OAuth authorization.

4. Setup and access instructions
The app can be opened directly without creating a WoW100% account.

Core features available without login:
- View overall collection categories and expansion progress
- Open achievements, mounts, and pets planners
- Search and filter tracked items
- Mark items manually as obtained
- Open external item references on Wowhead
- Read legal and privacy information

Optional Battle.net connection:
- Tap "Connexion"
- Sign in on the official Battle.net OAuth page
- Authorize the "wow.profile" scope
- Select a World of Warcraft character
- The dashboard then shows character information and collection progress based on Battle.net data

Demo Battle.net account for review, if provided:
Email: [DEMO EMAIL]
Password: [DEMO PASSWORD]

If no demo account is provided:
The Battle.net connection is optional and uses Blizzard's official OAuth flow. A complete video demonstration is provided above so the review team can see the connected user flow.

5. External services, tools, or platforms
WoW100% uses the following external services and platforms:
- Blizzard Battle.net OAuth and World of Warcraft Profile APIs for optional user-authorized character, achievement, mount, and pet data
- Cloudflare Pages Functions hosted at https://wow100.cosmos-lty.fr/api to securely exchange OAuth codes and proxy Battle.net API requests
- Wowhead links as external reference pages for World of Warcraft items and achievements
- Locally bundled catalog data for achievements, mounts, pets, expansions, and metadata
- Local device storage via Flutter shared_preferences for the Battle.net access token, selected character, and manual checklist state

The app does not use payment processors, advertising networks, analytics SDKs, or AI services.

6. Regional differences
The app functions consistently across all regions. There are no region-specific features or region-specific paid content. The current Battle.net integration is configured for the EU Battle.net region.

7. Regulated industry or third-party protected material
WoW100% does not operate in a highly regulated industry.

WoW100% is an independent, unofficial companion app for World of Warcraft. World of Warcraft, Battle.net, Blizzard Entertainment, and related names or marks belong to their respective owners. The app uses user-authorized Battle.net API data and public reference links to help users track their own collection progress. The app includes legal information and a privacy policy in-app explaining that it is not affiliated with Blizzard Entertainment.

Please let us know if any additional information is needed.

Best regards,
Laetitia BARA
```

