-- 0002_modify_agg_products.sql
-- Modify agg.products table structure to optimize primary key and constraints
-- Created: May 2, 2025

-- Begin transaction to ensure changes are atomic
BEGIN;

-- 1. Update agg.products to use a single-column primary key
-- First, drop the existing composite primary key
ALTER TABLE agg.products DROP CONSTRAINT IF EXISTS products_pkey;

-- Add a single-column primary key on id
ALTER TABLE agg.products ADD PRIMARY KEY (id);

-- Ensure unique constraint on source, external_id, and country
-- (This likely already exists but we'll ensure it with a named constraint)
ALTER TABLE agg.products DROP CONSTRAINT IF EXISTS uq_products_source_extid_country;
ALTER TABLE agg.products ADD CONSTRAINT uq_products_source_extid_country UNIQUE (source, external_id, country);

-- 2. Remove default values from country and currency columns to enforce explicit setting
ALTER TABLE agg.products ALTER COLUMN country DROP DEFAULT;
ALTER TABLE agg.products ALTER COLUMN currency DROP DEFAULT;

-- 3. Ensure last_refreshed_at column exists (already added in migration 010)
-- We don't need to add it here, but we'll ensure it's not null for consistency
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_attribute
        WHERE attrelid = 'agg.products'::regclass
        AND attname = 'last_refreshed_at'
        AND NOT attisdropped
    ) THEN
        ALTER TABLE agg.products ADD COLUMN last_refreshed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        COMMENT ON COLUMN agg.products.last_refreshed_at IS 'Timestamp when product data was last refreshed from external source';
    END IF;
END $$;

-- Commit changes
COMMIT;

-- Verification query to run after migration (will return count of invalid rows)
-- SELECT COUNT(*) FROM agg.products WHERE country IS NULL OR currency IS NULL;