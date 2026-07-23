# Release process

Public macOS builds must be signed with Developer ID, use the hardened runtime,
be notarized by Apple, have a stapled ticket, and pass Gatekeeper assessment.
The scripts intentionally fail closed if any of these checks does not pass.

## One-time Apple setup

The Apple Developer team used for a release must own all of the following:

- The `Developer ID Application` certificate in the signing Keychain.
- `com.whoopscope.mac`.
- `com.whoopscope.mac.widget`.
- The App Group configured in `Project.swift`.
- Developer ID provisioning profiles for the app and widget extension that
  include that App Group.

All team identifiers in `Project.swift` must belong to that same team. Never
change only the signing certificate: restricted entitlements must also match
the provisioning profiles.

Store notarization credentials in Keychain without committing them:

```bash
xcrun notarytool store-credentials WhoopScope \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

## Prepare a release

1. Update `VERSION` with a semantic prerelease or stable version.
2. Update `appVersion` and `buildNumber` in `Project.swift`.
3. Add user-facing notes at `docs/releases/vVERSION.md`.
4. Run all app and broker tests.
5. Commit and push a clean `main` branch.

Build, notarize, staple, package, and checksum:

```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID \
NOTARY_PROFILE=WhoopScope \
Scripts/release/build-release.sh
```

The official bundle prefix defaults to `com.whoopscope`, and the App Group
defaults to `YOUR_TEAM_ID.com.whoopscope.shared`. A fork can override both:

```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID \
BUNDLE_PREFIX=com.yourname.whoopscope \
APP_GROUP=YOUR_TEAM_ID.com.yourname.whoopscope.shared \
NOTARY_PROFILE=WhoopScope \
Scripts/release/build-release.sh
```

The output is written under `release/vVERSION/`, which is ignored by Git.
Verify the resulting archive independently:

```bash
Scripts/release/verify-release.sh
```

## Publish

The publish script requires a clean commit matching `origin/main`. It creates
an annotated Git tag, pushes it, verifies the packaged app again, creates a GitHub
prerelease, and uploads the app archive, SHA-256 checksums, and demo:

```bash
Scripts/release/publish-release.sh
```

After publishing:

1. Download the archive from GitHub on a different Mac user account.
2. Verify the checksum and launch through Finder.
3. Confirm Gatekeeper shows the identified developer without a warning.
4. Verify WHOOP sign-in, refresh, menu bar, widgets, Siri/Spotlight, and both
   model-provider privacy boundaries.
5. Update the landing page's release metadata and redeploy the saved site
   version.

Never upload an unsigned, ad-hoc-signed, Apple Development-signed, unstapled,
or failed-Gatekeeper build as a public release.

## Website

The landing page is free of analytics and is released from the same tagged
source as the app. Build and verify its connected Sites archive with:

```bash
Scripts/site/build-sites-archive.sh
```

The archive and checksum are written under `release/site/`. Save the version
from the exact pushed commit before deploying it. A production deployment
should only be created after the matching GitHub release and download artifact
are publicly available.
