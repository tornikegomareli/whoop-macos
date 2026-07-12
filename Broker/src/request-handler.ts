import {
  AUTHORIZATION_URL,
  CALLBACK_SCHEME,
  MAX_REQUEST_BYTES,
  REDIRECT_URI,
  SCOPES,
  TOKEN_URL,
} from "./constants";
import type { Environment } from "./environment";
import { emptyResponse, jsonResponse } from "./responses";
import { isTokenResponse } from "./token-response";

type Fetcher = typeof fetch;

export async function handleRequest(
  request: Request,
  env: Environment,
  fetcher: Fetcher,
): Promise<Response> {
  const url = new URL(request.url);

  if (request.headers.has("Origin")) {
    return jsonResponse({ error: "browser_requests_not_supported" }, 403);
  }

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse({ status: "ok" });
  }

  if (request.method === "GET" && url.pathname === "/v1/config") {
    return jsonResponse({
      client_id: env.WHOOP_CLIENT_ID,
      authorization_url: AUTHORIZATION_URL,
      redirect_uri: REDIRECT_URI,
      callback_scheme: CALLBACK_SCHEME,
      scopes: SCOPES,
    });
  }

  if (request.method === "POST" && url.pathname === "/v1/oauth/exchange") {
    const limited = await enforceRateLimit(request, env);
    if (limited) return limited;

    const body = await readJsonBody(request);
    if (!body || typeof body.code !== "string" || !isSafeToken(body.code)) {
      return jsonResponse({ error: "invalid_request" }, 400);
    }

    return proxyTokenRequest(
      [
        ["grant_type", "authorization_code"],
        ["code", body.code],
        ["redirect_uri", REDIRECT_URI],
        ["client_id", env.WHOOP_CLIENT_ID],
        ["client_secret", env.WHOOP_CLIENT_SECRET],
      ],
      fetcher,
    );
  }

  if (request.method === "POST" && url.pathname === "/v1/oauth/refresh") {
    const limited = await enforceRateLimit(request, env);
    if (limited) return limited;

    const body = await readJsonBody(request);
    if (
      !body ||
      typeof body.refresh_token !== "string" ||
      !isSafeToken(body.refresh_token)
    ) {
      return jsonResponse({ error: "invalid_request" }, 400);
    }

    return proxyTokenRequest(
      [
        ["grant_type", "refresh_token"],
        ["refresh_token", body.refresh_token],
        ["client_id", env.WHOOP_CLIENT_ID],
        ["client_secret", env.WHOOP_CLIENT_SECRET],
        ["scope", "offline"],
      ],
      fetcher,
    );
  }

  if (request.method === "OPTIONS") {
    return emptyResponse(405);
  }

  return jsonResponse({ error: "not_found" }, 404);
}

async function enforceRateLimit(
  request: Request,
  env: Environment,
): Promise<Response | null> {
  const instanceID = request.headers.get("X-WhoopScope-Install-ID");
  const fallbackIP = request.headers.get("CF-Connecting-IP") ?? "unknown";
  const key = instanceID && /^[A-Fa-f0-9-]{36}$/.test(instanceID)
    ? `install:${instanceID}`
    : `ip:${fallbackIP}`;
  const result = await env.TOKEN_RATE_LIMITER.limit({ key });
  return result.success
    ? null
    : jsonResponse({ error: "rate_limited" }, 429);
}

async function readJsonBody(
  request: Request,
): Promise<Record<string, unknown> | null> {
  if (request.headers.get("Content-Type")?.split(";", 1)[0] !== "application/json") {
    return null;
  }

  const declaredLength = Number(request.headers.get("Content-Length") ?? 0);
  if (declaredLength > MAX_REQUEST_BYTES) return null;

  try {
    const text = await request.text();
    if (new TextEncoder().encode(text).byteLength > MAX_REQUEST_BYTES) return null;
    const body: unknown = JSON.parse(text);
    return typeof body === "object" && body !== null
      ? (body as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}

function isSafeToken(value: string): boolean {
  return value.length > 0 && value.length <= 4_096;
}

async function proxyTokenRequest(
  values: ReadonlyArray<readonly [string, string]>,
  fetcher: Fetcher,
): Promise<Response> {
  const body = new URLSearchParams(values);
  const response = await fetcher(TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  if (response.status === 400 || response.status === 401) {
    return jsonResponse({ error: "invalid_grant" }, 401);
  }
  if (!response.ok) {
    return jsonResponse({ error: "upstream_unavailable" }, 502);
  }

  const payload: unknown = await response.json();
  if (!isTokenResponse(payload)) {
    return jsonResponse({ error: "invalid_upstream_response" }, 502);
  }

  return jsonResponse(payload);
}
