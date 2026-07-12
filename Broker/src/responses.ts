const SECURITY_HEADERS = {
  "Cache-Control": "no-store",
  "Content-Security-Policy": "default-src 'none'",
  "Referrer-Policy": "no-referrer",
  "X-Content-Type-Options": "nosniff",
} as const;

export function jsonResponse(body: unknown, status = 200): Response {
  return Response.json(body, {
    status,
    headers: SECURITY_HEADERS,
  });
}

export function emptyResponse(status = 204): Response {
  return new Response(null, {
    status,
    headers: SECURITY_HEADERS,
  });
}

