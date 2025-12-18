CREATE TABLE IF NOT EXISTS auth_users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Ensure case-insensitive uniqueness without CITEXT extension
CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_email_lower ON auth_users (lower(email));
