export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  scope: string;
  token_type: string;
}

export function isTokenResponse(value: unknown): value is TokenResponse {
  if (typeof value !== "object" || value === null) return false;
  const token = value as Record<string, unknown>;
  return (
    typeof token.access_token === "string" &&
    typeof token.refresh_token === "string" &&
    typeof token.expires_in === "number" &&
    typeof token.scope === "string" &&
    typeof token.token_type === "string"
  );
}

