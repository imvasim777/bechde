-- Align price_amount to match JPA double (float(53))
ALTER TABLE listings ALTER COLUMN price_amount TYPE double precision USING price_amount::double precision;
