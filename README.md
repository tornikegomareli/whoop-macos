# WhoopScope

WhoopScope is a native, privacy-first macOS dashboard for personal WHOOP data. The current build supports broker-backed WHOOP authentication, Keychain token storage and refresh, complete local synchronization of official activity data, a live Today dashboard, 7/30/90-day trends, detailed Sleep, Recovery, Strain & Cycles, and Workouts explorers, menu-bar and desktop widgets, Siri and Spotlight actions, grounded data chat, and a Tuist-managed iPhone companion for complementary Apple Health context.

Each explorer is backed by the synchronized local archive rather than sample data. Range controls update all four explorers, charts support date selection, history rows open native inspectors with the complete stored record, and Workouts includes activity and text filters.

## Requirements

- Apple silicon Mac running macOS 26 or later
- iPhone running iOS 26 or later for optional Apple Health enrichment
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

## Add complementary Apple Health data

WHOOP remains the only source for sleep and recovery. The iPhone companion requests read-only access to selected activity, mobility, mindfulness, hydration, cardio-fitness, and body-composition categories; it never requests HealthKit sleep data.

1. Keep the `WhoopScope` Mac app open so its local receiver is available.
2. In Xcode, select the `WhoopScopeCompanion` scheme and your iPhone, then run it.
3. Select **Allow Access & Prepare** and choose only the categories you want to share.
4. Select your Mac when it appears, connect, and send the prepared summaries.

Both devices need Wi-Fi and Bluetooth enabled. The transfer uses an encrypted Apple peer-to-peer session and does not use iCloud or a WhoopScope server. The Mac stores imported daily summaries in the same private local database as WHOOP data. Import status is visible in **Settings → Apple Health companion**.

## Ask your data

Open **Ask Your Data** to ask questions about synchronized WHOOP history and imported Apple Health summaries. WhoopScope selects a compact date range from the question, adds exact local evidence, and labels every answer with the sources and period used. Sleep and recovery evidence always comes only from WHOOP.

Apple Intelligence is the default provider. It runs through Apple's Foundation Models framework and keeps the prompt and response on the Mac. Apple Intelligence must be enabled and its on-device model must be ready.

OpenAI is an optional bring-your-own-key provider:

1. Open **Settings → Ask Your Data** and select **OpenAI**.
2. Enter your API key and, if desired, change the model name.
3. Save the key. It is stored in Keychain and is never written to the project or local database.

When OpenAI is selected, the question and its grounded evidence are sent directly to the OpenAI Responses API. Requests set `store` to `false`; the provider and privacy boundary remain visible in Settings and in the chat header.

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
- `Features/Explorers`: detailed sleep, recovery, cycle, and workout analysis with history inspectors.
- `Features/Chat`: evidence selection, grounded prompts, provider adapters, secure provider settings, and chat presentation.
- `Modules/WidgetSupport`: the minimal, display-only snapshot shared with WidgetKit.
- `Modules/HealthBridge`: encrypted local discovery and transfer between iPhone and Mac.
- `Apps/Widget`: small and medium desktop widgets that never access credentials or the WHOOP API.
- `Apps/Mac`: dependency composition, navigation, window, and menu-bar scenes.
- `Apps/iPhone`: read-only HealthKit companion, generated and maintained with Tuist.

Dependencies point inward toward the domain layer. Generated API DTOs, Keychain, WHOOP networking, HealthKit, and model providers remain infrastructure adapters.

## Privacy boundary

No credentials are present in the repository. Rotating user access and refresh tokens are stored in Keychain. The Client Secret exists only in the broker's encrypted deployment secrets. WHOOP records are stored in the user's Application Support directory and remain on the Mac.

WHOOP is the only source for sleep and recovery. The optional iPhone companion reads only complementary HealthKit categories selected by the user and transfers daily summaries directly to the Mac without iCloud storage. Apple Intelligence processing remains on-device. OpenAI is used only when the user selects it and supplies a Keychain-stored API key; the app then sends the question and grounded evidence directly to OpenAI with response storage disabled.
