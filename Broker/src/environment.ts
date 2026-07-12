export interface RateLimiter {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

export interface Environment {
  WHOOP_CLIENT_ID: string;
  WHOOP_CLIENT_SECRET: string;
  TOKEN_RATE_LIMITER: RateLimiter;
}

