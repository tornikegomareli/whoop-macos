# WhoopScope

WhoopScope is a native, privacy-first macOS dashboard for personal WHOOP data. The current build supports broker-backed WHOOP authentication, Keychain token storage and refresh, complete local synchronization of the official activity data, a live Today dashboard, 7/30/90-day trend comparisons, and a glanceable menu-bar widget.

## Requirements

- Apple silicon Mac running macOS 26 or later
- Xcode 26 or later
- [Mise](https://mise.jdx.dev/)

## Generate and run

```bash
mise trust
mise install
tuist install
tuist generate
open WhoopScope.xcworkspace
```

Select the `WhoopScope` scheme and run the macOS app. Generated Xcode projects and workspaces are intentionally excluded from Git.

## Connect WHOOP

Create a WHOOP Developer app with the redirect URI:

```text
whoopscope://oauth/callback
```

Enable `offline` and all six read scopes. WhoopScope uses a small authentication broker so the shared Client Secret never ships in the Mac app. Users open **Settings** and select **Connect WHOOP**; they never enter developer credentials.

### Run the broker locally

```bash
cd Broker
npm install
cp .dev.vars.example .dev.vars
# Fill .dev.vars locally. It is ignored by Git.
npm run dev
```

For local broker development, temporarily set `WHOOPSCOPE_BROKER_URL` in `Project.swift` to `http://127.0.0.1:8787`. Only localhost HTTP is accepted; deployed brokers must use HTTPS.

### Deploy the broker

```bash
cd Broker
npx wrangler login
npx wrangler secret put WHOOP_CLIENT_ID
npx wrangler secret put WHOOP_CLIENT_SECRET
npm run deploy
```

Wrangler prompts for each value and stores it as an encrypted Cloudflare secret. Never add the Client Secret to source code, Tuist manifests, build settings, `.xcconfig`, `.env`, or `.dev.vars` files that could be committed.

The app is configured to use the production broker at `https://whoopscope-auth.whoopscope.workers.dev`.

## Verify

```bash
mise exec -- tuist test WhoopScope --platform macOS
```

You can also build directly:

```bash
xcodebuild \
  -workspace WhoopScope.xcworkspace \
  -scheme WhoopScope \
  -destination 'platform=macOS,arch=arm64' \
  build
```

## Architecture

- `Modules/Domain`: framework-independent entities, repository contracts, and use cases.
- `Modules/Persistence`: GRDB-backed local persistence infrastructure.
- `Modules/Authentication`: public-client OAuth adapter, Keychain token storage, and broker client.
- `Modules/Data`: official WHOOP API transport, pagination, synchronization, and domain mapping.
- `Broker`: stateless Cloudflare Worker that adds the server-only Client Secret during token exchange and refresh.
- `Modules/PreviewData`: deterministic fixture implementations used before live OAuth is connected.
- `Modules/DesignSystem`: shared visual tokens and surfaces.
- `Features/Dashboard`: dashboard presentation and its observable model.
- `Features/Trends`: historical comparisons, interactive charts, and range selection.
- `Apps/Mac`: dependency composition, navigation, window, and menu-bar scenes.

Dependencies point inward toward the domain layer. Generated API DTOs, Keychain, WHOOP networking, HealthKit, and AI providers will remain infrastructure adapters.

## Privacy boundary

No credentials are present in the repository. Rotating user access and refresh tokens are stored in Keychain. The Client Secret exists only in the broker's encrypted deployment secrets. WHOOP records are stored in the user's Application Support directory and remain on the Mac.

WHOOP will remain the only source for sleep and recovery. A later iPhone companion will read only complementary HealthKit categories and transfer them directly to the paired Mac without iCloud storage.
