<p align="center">
  <img src="Apps/Mac/Resources/Assets.xcassets/AppIcon.appiconset/whoopscope-256.png" width="128" alt="WhoopScope app icon">
</p>

<h1 align="center">WhoopScope</h1>

<p align="center">
  A private, native macOS home for your WHOOP history.
</p>

<p align="center">
  <a href="https://github.com/tornikegomareli/whoop-macos/releases"><img alt="Latest release" src="https://img.shields.io/github/v/release/tornikegomareli/whoop-macos?include_prereleases&style=flat-square"></a>
  <a href="LICENSE"><img alt="Apache 2.0 license" src="https://img.shields.io/badge/license-Apache--2.0-blue?style=flat-square"></a>
  <img alt="macOS 26+" src="https://img.shields.io/badge/macOS-26%2B-black?style=flat-square&logo=apple">
  <a href="https://github.com/tornikegomareli/whoop-macos/actions"><img alt="Build status" src="https://img.shields.io/github/actions/workflow/status/tornikegomareli/whoop-macos/ci.yml?branch=main&style=flat-square"></a>
</p>

![WhoopScope Today dashboard using synthetic sample data](docs/images/dashboard.png)

WhoopScope synchronizes the data available through WHOOP's official Developer
API and turns it into a fast local dashboard, long-range trends, detailed
explorers, widgets, Siri and Spotlight actions, and grounded conversations
about your own history.

The project is free and open source. Health records stay on the Mac unless you
explicitly choose a cloud model and supply your own API key.

> [!IMPORTANT]
> WhoopScope is in early access. The shared WHOOP application is currently
> limited to 10 WHOOP members until WHOOP approves it for broader access.
> Source builds and the synthetic demo are available to everyone; if all 10
> places are occupied, a new member cannot connect through the official build
> until approval or a place becomes available.

## Highlights

- Official WHOOP API coverage for profile, body measurements, cycles,
  recovery, sleep, and workouts.
- Keychain-backed OAuth tokens with automatic refresh through a minimal,
  stateless authentication broker.
- Native Today dashboard, 7/30/90-day trends, detailed record inspectors, and
  activity filtering.
- A compact menu-bar dashboard and small/medium WidgetKit desktop widgets.
- Siri, Shortcuts, and Spotlight actions for frequently requested metrics.
- Grounded data chat through Apple's on-device Foundation Models framework or
  OpenAI with your own Keychain-stored API key.
- Optional iPhone companion for complementary Apple Health activity, mobility,
  mindfulness, hydration, cardio-fitness, and body-composition summaries.
  HealthKit sleep is intentionally never requested or merged.
- Deterministic sample mode for development, screenshots, and bug reports.

## See it in action

[Watch the 13-second WhoopScope demo](docs/media/whoopscope-demo.mp4).
Every number shown in the demo and screenshots is synthetic.

| Trends | Workout explorer |
| --- | --- |
| ![Thirty-day WhoopScope trends using sample data](docs/images/trends.png) | ![WhoopScope workout explorer using sample data](docs/images/workouts.png) |

<p align="center">
  <img src="docs/images/menu-bar.png" width="380" alt="WhoopScope menu-bar summary using sample data">
</p>

## Download

Download
[WhoopScope 0.1.0-alpha.1 for macOS](https://github.com/tornikegomareli/whoop-macos/releases/download/v0.1.0-alpha.1/WhoopScope-0.1.0-alpha.1-macOS.zip).
The matching
[SHA-256 checksum](https://github.com/tornikegomareli/whoop-macos/releases/download/v0.1.0-alpha.1/SHA256SUMS.txt)
and [release notes](https://github.com/tornikegomareli/whoop-macos/releases/tag/v0.1.0-alpha.1)
are published alongside the build.

WhoopScope currently requires:

- Apple silicon Mac.
- macOS 26 or later.
- A WHOOP account for live synchronization.
- Only for chat: Apple Intelligence enabled for on-device answers, or your own
  OpenAI API key for the optional cloud provider.

The release page states the signing and notarization status of each build.
SHA-256 checksums are attached beside downloadable builds.

## Connect your WHOOP account

### Using the official WhoopScope release

You do **not** need to create a WHOOP Developer application or run a server.
The project maintainer operates the shared authentication broker used by the
official build.

1. Download the release ZIP, open it, and move `WhoopScope.app` to
   `/Applications`.
2. Open WhoopScope. macOS may ask you to confirm the first launch.
3. Open **Settings**, find **WHOOP account**, and click **Connect WHOOP**.
4. Your default browser opens WHOOP's official sign-in and authorization page
   on `api.prod.whoop.com`. Sign in with your normal WHOOP account.
5. Review the access requested by WhoopScope, then approve it. The app requests
   read-only access to your profile, body measurements, cycles/strain,
   recovery, sleep, and workouts, plus `offline` access so it can stay signed
   in.
6. WHOOP returns you to `whoopscope://oauth/callback`. The browser
   authorization window closes, WhoopScope becomes active, and the first local
   sync begins.
7. Leave the app installed and it will refresh expiring authorization
   automatically. If WHOOP revokes or expires the authorization, Settings will
   ask you to reconnect.

To stop access, choose **Settings → WHOOP account → Disconnect and Revoke
Access**. WhoopScope revokes the WHOOP authorization, deletes its tokens from
Keychain, and stops synchronizing. You can also revoke the integration from
the WHOOP app.

An ordinary user does **not** need:

- A WHOOP Developer Dashboard account, Client ID, or Client Secret.
- A Cloudflare account, Worker deployment, or hosted server.
- Xcode, Tuist, or an Apple Developer membership.
- An OpenAI API key unless they deliberately select OpenAI for chat.

The official build shares one WHOOP Developer application. WHOOP's
[App Approval documentation](https://developer.whoop.com/docs/developing/app-approval/)
currently allows an unapproved application to serve up to 10 members. If the
allowance is full, a new WHOOP account cannot connect through the official
build until WHOOP approves the application for more members. Anyone can still
build and run the synthetic `WhoopScope Demo` scheme locally.

### What the authentication broker does

The official app cannot safely contain a WHOOP Client Secret, so the maintainer
hosts a small, stateless Cloudflare Worker. Free and open-source distribution
does not remove this OAuth security requirement.

1. The Mac app opens WHOOP's authorization page.
2. After you consent, the Mac app sends the one-time authorization code to the
   broker.
3. The broker exchanges that code—and later rotating refresh tokens—with
   WHOOP using the server-side Client Secret.
4. The Mac app stores the returned access and refresh tokens in Apple Keychain.
5. The Mac app downloads your health records directly from WHOOP's API into
   its local database.

The broker does not keep accounts, tokens, or health records, and WHOOP API
health-data requests do not pass through it. WHOOP documents the consent,
authorization-code, refresh-token, and revocation behavior in its
[OAuth guide](https://developer.whoop.com/docs/developing/oauth/).

The maintainer must keep the official broker deployed and available for users
to sign in and refresh authorization. End users never deploy it themselves.

## Build from source

Install Xcode 26 or later and [Mise](https://mise.jdx.dev/), then:

```bash
git clone https://github.com/tornikegomareli/whoop-macos.git
cd whoop-macos
mise trust
mise install
tuist install
tuist generate
open WhoopScope.xcworkspace
```

Select the `WhoopScope` scheme for live data. Select `WhoopScope Demo` for a
fully local synthetic archive that does not access Keychain, WHOOP, the live
widget snapshot, or the Apple Health receiver.

The checked-in signing defaults reproduce the official project. To sign a
fork with your own Apple Developer team, generate it with identifiers owned by
that team:

```bash
TUIST_WHOOPSCOPE_DEVELOPMENT_TEAM=YOUR_TEAM_ID \
TUIST_WHOOPSCOPE_BUNDLE_PREFIX=com.yourname.whoopscope \
TUIST_WHOOPSCOPE_APP_GROUP=YOUR_TEAM_ID.com.yourname.whoopscope.shared \
tuist generate
```

Create the matching App IDs and App Group in the Apple Developer portal first.
These values are build configuration, not secrets.

Run the complete macOS test suite with:

```bash
mise exec -- tuist test WhoopScope --platform macOS
```

### Connect a fork to WHOOP

These steps are for people distributing or developing a fork. They are **not**
required for users of the official WhoopScope release.

1. Create your own application in the
   [WHOOP Developer Dashboard](https://developer-dashboard.whoop.com/). Provide
   your fork's name, contact email, and a publicly accessible privacy-policy
   URL.
2. Register this exact redirect URI:

   ```text
   whoopscope://oauth/callback
   ```

3. Enable these seven scopes: `offline`, `read:profile`,
   `read:body_measurement`, `read:cycles`, `read:recovery`, `read:sleep`, and
   `read:workout`.
4. Copy the Client ID and Client Secret. Never add the Client Secret to the Mac
   app, `Project.swift`, source control, build settings, or logs.
5. Deploy the Worker in [`Broker`](Broker) under your own Cloudflare account
   and store the credentials as its encrypted `WHOOP_CLIENT_ID` and
   `WHOOP_CLIENT_SECRET` secrets.
6. Set `WHOOPSCOPE_BROKER_URL` in `Project.swift` to your Worker's HTTPS URL,
   regenerate the workspace, and test sign-in, refresh, and revocation.
7. If your fork can be installed beside WhoopScope, replace the
   `whoopscope` URL scheme and matching redirect URI throughout the app,
   broker, WHOOP configuration, tests, and App Intents with a unique scheme.
8. Before serving more than 10 WHOOP members, submit your own WHOOP application
   for approval.

Every public fork must use its own WHOOP application and broker. Do not point a
fork at the hosted official WhoopScope broker. See
[Broker/README.md](Broker/README.md) for deployment, testing, and secret
rotation instructions.

## Privacy model

- WHOOP and imported Apple Health summaries are stored in the app's private
  Application Support directory.
- WHOOP tokens and model API keys are stored in Apple Keychain.
- The authentication broker exchanges and refreshes tokens but does not store
  them or receive WHOOP health records.
- Apple Health summaries travel directly from iPhone to Mac over an encrypted
  local peer-to-peer session after the Mac user approves the invitation.
- The Mac app uses App Sandbox and limits its entitlements to its App Group
  and client/server networking required by its documented features.
- Apple Foundation Models processing stays on-device.
- When OpenAI is selected, WhoopScope shows that grounded evidence will leave
  the Mac, uses the user's own key, and sets response storage to disabled.
- The app contains no advertising, analytics, or behavioral tracking.

Read the full [privacy policy](PRIVACY.md) and
[security policy](SECURITY.md).

## Architecture

```text
Apps/Mac ───────┬── Features/{Dashboard,Trends,Explorers,Chat,Settings}
                ├── Modules/{Authentication,Data,Persistence,HealthBridge}
                └── Modules/{Domain,DesignSystem,WidgetSupport,PreviewData}

Apps/Widget ─────── Modules/WidgetSupport
Apps/iPhone ─────── Modules/{Domain,HealthBridge}
Broker ──────────── WHOOP OAuth token endpoints only
```

The domain layer owns entities and repository contracts. Infrastructure
adapters handle WHOOP networking, GRDB, Keychain, local device transfer, and
model providers. UI features depend inward on domain use cases. Tuist keeps
the project graph reproducible without committing generated Xcode projects.

## Project status

The current focus is a trustworthy first public prerelease:

- The codebase and demo are open for review and contribution.
- Public binary packaging, signing, and notarization are being verified.
- WHOOP sign-in remains capacity-limited until application approval.
- The iPhone companion is built from source for now; it is not yet distributed
  separately through TestFlight or the App Store.

WhoopScope is an educational fitness-history tool, not a medical device. It
does not diagnose conditions or provide medical advice.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Never
attach real health records, database files, API keys, or authentication tokens
to an issue. Use the `WhoopScope Demo` scheme for reproducible reports.

Security reports must follow [SECURITY.md](SECURITY.md).
Sample workflows and grounded question ideas are in
[docs/EXAMPLES.md](docs/EXAMPLES.md).
Maintainer signing and notarization steps are in
[docs/RELEASING.md](docs/RELEASING.md).

## License and trademarks

WhoopScope is released under the
[Apache License 2.0](LICENSE). Third-party notices are in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

WHOOP is a trademark of WHOOP, Inc. WhoopScope is an independent project and
is not affiliated with, endorsed by, or sponsored by WHOOP, Inc. Apple,
Apple Health, Siri, Spotlight, and macOS are trademarks of Apple Inc. OpenAI
is a trademark of OpenAI, L.L.C.
