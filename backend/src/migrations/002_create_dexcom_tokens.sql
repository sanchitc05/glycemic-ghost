CREATE TABLE IF NOT EXISTS dexcom_tokens (
  user_id       TEXT PRIMARY KEY,
  access_token  TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at    TIMESTAMPTZ NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
