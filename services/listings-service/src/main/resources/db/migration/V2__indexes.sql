-- Full-text search index and helpers
CREATE INDEX IF NOT EXISTS idx_listings_fts ON listings USING GIN (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,'')));
CREATE INDEX IF NOT EXISTS idx_listings_city ON listings (city);
