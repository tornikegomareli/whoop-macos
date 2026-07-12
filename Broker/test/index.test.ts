import { describe, expect, it, vi } from "vitest";
import type { Environment, RateLimiter } from "../src/environment";
import { handleRequest } from "../src/request-handler";

function environment(rateLimiter?: RateLimiter): Environment {
  return {
    WHOOP_CLIENT_ID: "public-client-id",
    WHOOP_CLIENT_SECRET: "server-only-secret",
    TOKEN_RATE_LIMITER: rateLimiter ?? {
      limit: async () => ({ success: true }),
    },
  };
}

describe("WhoopScope auth broker", () => {
  it("returns public OAuth configuration without the secret", async () => {
    const response = await handleRequest(
      new Request("https://broker.example/v1/config"),
      environment(),
      vi.fn(),
    );
    const body = await response.json() as Record<string, unknown>;

    expect(response.status).toBe(200);
    expect(body.client_id).toBe("public-client-id");
    expect(body.redirect_uri).toBe("whoopscope://oauth/callback");
    expect(JSON.stringify(body)).not.toContain("server-only-secret");
  });

  it("adds the secret only to the upstream code exchange", async () => {
    const fetcher = vi.fn(async (_url: string | URL | Request, init?: RequestInit) => {
      const form = new URLSearchParams(init?.body as URLSearchParams);
      expect(form.get("client_secret")).toBe("server-only-secret");
      expect(form.get("code")).toBe("authorization-code");
      return Response.json({
        access_token: "access",
        refresh_token: "refresh",
        expires_in: 3600,
        scope: "offline read:profile",
        token_type: "bearer",
      });
    });

    const response = await handleRequest(
      new Request("https://broker.example/v1/oauth/exchange", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-WhoopScope-Install-ID": "2AA852BB-6DF1-4AF2-A8D7-A5E22494956A",
        },
        body: JSON.stringify({ code: "authorization-code" }),
      }),
      environment(),
      fetcher as typeof fetch,
    );

    expect(response.status).toBe(200);
    expect(fetcher).toHaveBeenCalledOnce();
  });

  it("rejects browser-originated requests", async () => {
    const response = await handleRequest(
      new Request("https://broker.example/v1/oauth/exchange", {
        method: "POST",
        headers: {
          Origin: "https://malicious.example",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ code: "authorization-code" }),
      }),
      environment(),
      vi.fn(),
    );

    expect(response.status).toBe(403);
  });

  it("returns 429 when the limiter rejects a request", async () => {
    const response = await handleRequest(
      new Request("https://broker.example/v1/oauth/refresh", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh_token: "refresh" }),
      }),
      environment({ limit: async () => ({ success: false }) }),
      vi.fn(),
    );

    expect(response.status).toBe(429);
  });
});
