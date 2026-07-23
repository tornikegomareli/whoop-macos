# Contributing to WhoopScope

Thanks for helping improve WhoopScope. Bug fixes, accessibility improvements,
tests, documentation, and focused feature proposals are welcome.

## Before opening a change

- Search existing issues and discussions.
- For a substantial feature or architectural change, open a proposal first.
- Never attach real WHOOP exports, access tokens, API keys, screenshots of a
  real account, or other personal health information.
- Use the `WhoopScope Demo` scheme when a report needs reproducible sample data.

## Local setup

You need an Apple silicon Mac with macOS 26 or later, Xcode 26 or later, and
[Mise](https://mise.jdx.dev/).

```bash
mise trust
mise install
tuist install
tuist generate
open WhoopScope.xcworkspace
```

Run the app with synthetic data by selecting the `WhoopScope Demo` scheme.
That scheme does not access Keychain, WHOOP, the live widget snapshot, or the
Apple Health receiver.

## Tests and checks

Before opening a pull request:

```bash
mise exec -- tuist test WhoopScope --platform macOS
cd Broker
npm ci
npm run check
npm test
```

Keep changes focused and include tests for behavior changes. Generated Xcode
projects and workspaces must not be committed.

## Pull requests

Explain the user-facing problem, the chosen approach, privacy implications,
and how the change was verified. By contributing, you agree that your
contribution is licensed under the Apache License 2.0.

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).
