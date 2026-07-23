# WhoopScope authentication broker

This Cloudflare Worker keeps a WHOOP OAuth Client Secret out of the native
apps. It accepts only token exchange and refresh requests, forwards them to
WHOOP over HTTPS, and returns WHOOP's response without storing credentials or
health data.

Every public fork must deploy its own worker and use its own WHOOP Developer
application. Never reuse the hosted WhoopScope broker for a differently
branded or modified app.

## Prerequisites

- A WHOOP Developer application.
- A Cloudflare account with Workers enabled.
- Node.js 22 or later.

Configure the WHOOP application with this redirect URI:

```text
whoopscope://oauth/callback
```

Enable the `offline` scope for refresh tokens and all six read scopes used by
WhoopScope.

## Run locally

```bash
npm ci
cp .dev.vars.example .dev.vars
```

Fill `.dev.vars` locally, then run:

```bash
npm run check
npm test
npm run dev
```

`.dev.vars` is ignored by Git. Do not paste secrets into source files, build
settings, issue reports, screenshots, or logs.

For local broker development, temporarily change `WHOOPSCOPE_BROKER_URL` in
the macOS target's Info.plist settings in `Project.swift` to
`http://127.0.0.1:8787`. The app accepts plain HTTP only for loopback hosts.

## Deploy

Authenticate Wrangler and set both encrypted secrets:

```bash
npx wrangler login
npx wrangler secret put WHOOP_CLIENT_ID --name whoopscope-auth
npx wrangler secret put WHOOP_CLIENT_SECRET --name whoopscope-auth
npm run deploy
```

Copy the deployed HTTPS Worker URL into `WHOOPSCOPE_BROKER_URL` in
`Project.swift`, regenerate the project, and test a complete sign-in plus token
refresh.

The `compatibility_date` in `wrangler.jsonc` cannot be later than the date on
which you deploy. Update it when necessary.

## Rotate credentials

Rotate immediately if a Client Secret was pasted into a command argument,
terminal transcript, issue, chat, or other durable history:

1. Generate a new Client Secret in the WHOOP Developer Dashboard.
2. Run `npx wrangler secret put WHOOP_CLIENT_SECRET --name whoopscope-auth`.
3. Deploy the Worker and verify sign-in.
4. Revoke the old secret in the WHOOP Developer Dashboard.

Changing a Worker secret creates a new deployment automatically in current
Wrangler versions, but running `npm run deploy` afterward also verifies the
checked-in Worker configuration.

## Production checklist

- Keep preview URLs disabled.
- Restrict CORS and request methods in code.
- Keep the token endpoint rate limiter enabled.
- Do not add request-body logging or token analytics.
- Run `npm audit`, `npm run check`, and `npm test`.
- Review Cloudflare logs only for non-sensitive operational metadata.
- Apply for WHOOP approval before exceeding the platform's pre-approval member
  limit.
