# WhoopScope Privacy Policy

Last updated: July 11, 2026

WhoopScope is a personal, educational application that helps its user view and analyze their own WHOOP data and, optionally, complementary Apple Health data.

## Data accessed

With your authorization, WhoopScope may access data exposed by the official WHOOP Developer API, including profile information, body measurements, physiological cycles, recovery, sleep, and workouts.

An optional iPhone companion may access specifically selected Apple Health data that complements WHOOP data. WhoopScope does not request or access Apple Health sleep data. WHOOP remains the sole source for sleep and recovery information.

## Storage

Health and fitness data is stored locally on devices you control. Authentication tokens and AI-provider API keys are stored in Apple Keychain. WHOOP and imported Apple Health summaries are stored in the application's private Application Support directory and are protected by your macOS account and FileVault when FileVault is enabled. Apple Health summaries move from iPhone to Mac through an encrypted, direct Apple peer-to-peer session.

WhoopScope does not use iCloud to store personal health information.

## Authentication broker

WhoopScope uses a minimal Cloudflare-hosted authentication broker to keep the WHOOP application Client Secret out of downloadable apps. The broker processes authorization codes and refresh tokens transiently over encrypted connections. It does not persist tokens, retrieve WHOOP health records, or receive the health and fitness data returned by WHOOP's data APIs.

## AI features

When an on-device or local AI provider is selected, health data remains on your devices.

When you explicitly select a cloud AI provider, the minimum data required to answer your question is sent directly to that provider using an API key you supply. WhoopScope clearly indicates when data may leave your device. The selected provider's privacy policy and data-handling terms also apply.

## Sharing and tracking

WhoopScope does not sell personal information. It contains no advertising, third-party analytics, or behavioral tracking.

Data is not shared with third parties except when:

- You authorize WHOOP to provide your data to WhoopScope.
- You explicitly choose a cloud AI provider to process a question.
- Disclosure is required by law.

## Retention and deletion

Data remains on your devices until you remove the application's local data or uninstall the application. Signing out revokes WhoopScope's WHOOP authorization and removes its credentials and tokens from Keychain.

## Security

WhoopScope uses encrypted network connections, restricted local application storage, and Apple Keychain to protect sensitive information. Enabling FileVault provides encryption at rest for data stored on the Mac.

## Contact

For privacy or support questions, contact the developer through [Tornike Gomareli's GitHub profile](https://github.com/tornikegomareli).
