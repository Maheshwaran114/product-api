-- 0003_tweak_aff_and_fin.sql
-- Tweak affiliate and financial tables to standardize PK structure and enforce explicit country and currency setting
-- Created: May 2, 2025

-- Begin transaction to ensure atomicity
BEGIN;

-- 1. Update aff.affiliate_products table structure
-- Drop the composite primary key and add a single-column PK
DO $$
BEGIN
    -- Check if the composite PK exists and drop it
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'affiliate_products_pkey' 
        AND contype = 'p'
        AND conrelid = 'aff.affiliate_products'::regclass
    ) THEN
        ALTER TABLE aff.affiliate_products DROP CONSTRAINT affiliate_products_pkey;
    END IF;
    
    -- Add a single-column PK if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'aff.affiliate_products'::regclass 
        AND contype = 'p'
    ) THEN
        ALTER TABLE aff.affiliate_products ADD PRIMARY KEY (id);
    END IF;
END $$;

-- Add a unique constraint on (product_id, country) if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'uq_affiliate_products_product_country' 
        AND conrelid = 'aff.affiliate_products'::regclass
    ) THEN
        ALTER TABLE aff.affiliate_products 
        ADD CONSTRAINT uq_affiliate_products_product_country 
        UNIQUE (product_id, country);
    END IF;
END $$;

-- If a currency column exists in aff.affiliate_products, drop any default
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'aff' 
        AND table_name = 'affiliate_products' 
        AND column_name = 'currency'
        AND column_default IS NOT NULL
    ) THEN
        ALTER TABLE aff.affiliate_products ALTER COLUMN currency DROP DEFAULT;
    END IF;
END $$;

-- 2. Update financial tables to enforce explicit country setting

-- For fin.transactions, remove any default from country column
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'fin' 
        AND table_name = 'transactions' 
        AND column_name = 'country'
        AND column_default IS NOT NULL
    ) THEN
        ALTER TABLE fin.transactions ALTER COLUMN country DROP DEFAULT;
    END IF;
END $$;

-- For fin.payouts, remove any default from country column
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'fin' 
        AND table_name = 'payouts' 
        AND column_name = 'country'
        AND column_default IS NOT NULL
    ) THEN
        ALTER TABLE fin.payouts ALTER COLUMN country DROP DEFAULT;
    END IF;
END $$;

-- Commit changes
COMMIT;

-- Validation query (commented out):
-- Confirm no defaults remain:
-- SELECT table_schema, table_name, column_name, column_default
--   FROM information_schema.columns
--  WHERE table_schema IN ('aff','fin')
--    AND column_name='country';