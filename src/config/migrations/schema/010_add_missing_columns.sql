-- 010_add_missing_columns.sql
-- Adding missing columns and implementing additional schema enhancements
-- Created: May 2, 2025

-- Add updated_at column to any tables missing it

-- Check if agg.products is missing updated_at and add it if needed
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_attribute
        WHERE attrelid = 'agg.products'::regclass
        AND attname = 'updated_at'
        AND NOT attisdropped
    ) THEN
        ALTER TABLE agg.products ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Check if aff.affiliate_products is missing updated_at and add it if needed
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_attribute
        WHERE attrelid = 'aff.affiliate_products'::regclass
        AND attname = 'updated_at'
        AND NOT attisdropped
    ) THEN
        ALTER TABLE aff.affiliate_products ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Add data freshness tracking column to relevant tables
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

-- Add missing indexes for better performance

-- Index for searches by external_id and country
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_products_external_id_country'
    ) THEN
        CREATE INDEX idx_products_external_id_country ON agg.products(external_id, country);
    END IF;
END $$;

-- Add encryption capabilities for GDPR-sensitive fields
DO $$
BEGIN
    -- Ensure pgcrypto extension is available
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    
    -- Add encryption functions if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'encrypt_pii') THEN
        CREATE OR REPLACE FUNCTION encrypt_pii(data TEXT, key TEXT)
        RETURNS BYTEA AS $$
        BEGIN
            RETURN pgp_sym_encrypt(data, key);
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        CREATE OR REPLACE FUNCTION decrypt_pii(data BYTEA, key TEXT)
        RETURNS TEXT AS $$
        BEGIN
            RETURN pgp_sym_decrypt(data, key);
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        COMMENT ON FUNCTION encrypt_pii(TEXT, TEXT) IS 'Encrypts PII data for GDPR compliance';
        COMMENT ON FUNCTION decrypt_pii(BYTEA, TEXT) IS 'Decrypts PII data for authorized access';
    END IF;
END $$;

-- Add any columns that may have been missed in initial schema creation
ALTER TABLE users.users ADD COLUMN IF NOT EXISTS last_login_ts TIMESTAMPTZ;
ALTER TABLE users.users ADD COLUMN IF NOT EXISTS account_locked BOOLEAN NOT NULL DEFAULT FALSE;

-- Add versioning column to handle optimistic concurrency control
ALTER TABLE agg.products ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE aff.affiliate_products ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE users.users ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;

-- Add metadata columns for tracking
ALTER TABLE users.users ADD COLUMN IF NOT EXISTS ip_address INET;
ALTER TABLE users.users ADD COLUMN IF NOT EXISTS user_agent TEXT;

-- Comment on tables and columns for better documentation
COMMENT ON TABLE users.users IS 'Primary users table with GDPR compliance';
COMMENT ON COLUMN users.users.deletion_requested IS 'Flag indicating user has requested account deletion (GDPR)';
COMMENT ON COLUMN users.users.country IS 'Country code for market segmentation and regional compliance';