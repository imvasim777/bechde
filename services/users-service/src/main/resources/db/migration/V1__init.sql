CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY,
    display_name VARCHAR(50),
    city TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_profiles_city ON user_profiles (city);
