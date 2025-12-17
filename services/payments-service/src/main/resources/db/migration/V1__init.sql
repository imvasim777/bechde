CREATE TABLE IF NOT EXISTS payment_sessions (
    id UUID PRIMARY KEY,
    listing_id UUID NOT NULL,
    placement_type TEXT NOT NULL CHECK (placement_type IN ('featured','boosted')),
    stripe_session_id TEXT UNIQUE,
    status TEXT NOT NULL CHECK (status IN ('created','paid','canceled')),
    amount_cents INTEGER NOT NULL DEFAULT 0,
    currency TEXT NOT NULL CHECK (currency IN ('USD','INR','EUR')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payment_events (
    id BIGSERIAL PRIMARY KEY,
    stripe_event_id TEXT UNIQUE,
    type TEXT,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payment_events_type ON payment_events(type);
