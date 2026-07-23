# WhoopScope website

The landing page is a static Next.js route packaged for Cloudflare with
OpenNext. Product media is copied from the privacy-safe `WhoopScope Demo`
scheme.

```bash
npm ci
npm run check
npm run build:cloudflare
```

Use `npm run dev` for local design work. Production versions and deployments
are managed through the connected Sites project recorded in
`.openai/hosting.json` at the repository root.

The entire site is part of the Apache 2.0-licensed WhoopScope repository. It
does not include analytics, advertising, paid features, or a separate account
system.
