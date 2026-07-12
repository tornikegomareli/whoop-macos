export const AUTHORIZATION_URL = "https://api.prod.whoop.com/oauth/oauth2/auth";
export const TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token";
export const REDIRECT_URI = "whoopscope://oauth/callback";
export const CALLBACK_SCHEME = "whoopscope";
export const MAX_REQUEST_BYTES = 8_192;

export const SCOPES = [
  "offline",
  "read:profile",
  "read:body_measurement",
  "read:cycles",
  "read:recovery",
  "read:sleep",
  "read:workout",
] as const;

