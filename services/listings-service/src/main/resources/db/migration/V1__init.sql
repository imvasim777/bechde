CREATE TABLE IF NOT EXISTS listings (
    id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price_amount NUMERIC NOT NULL,
    price_currency VARCHAR(3) NOT NULL,
    category TEXT NOT NULL,
    city TEXT NOT NULL,
    lat DOUBLE PRECISION NULL,
    lon DOUBLE PRECISION NULL,
    status TEXT NOT NULL,
    slug TEXT,
    published_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_listings_slug ON listings(slug);
