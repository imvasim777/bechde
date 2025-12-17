CREATE TABLE IF NOT EXISTS media_items (
    id UUID PRIMARY KEY,
    filename TEXT NOT NULL,
    content_type TEXT,
    blob_url TEXT NOT NULL,
    owner_id UUID NULL,
    listing_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_media_listing ON media_items(listing_id);
