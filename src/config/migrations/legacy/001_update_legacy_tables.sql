-- 001_update_legacy_tables.sql
-- Update legacy tables for compatibility with new multi-schema architecture
-- Created: May 1, 2025

-- Add country column to legacy product tables if they exist
DO $$
DECLARE
    tbl_name text;
    country_code text;
BEGIN
    -- Loop through possible tables for different country stores
    FOR tbl_name, country_code IN 
        VALUES 
            ('products_amazon_uk', 'GB'),
            ('products_amazon_us', 'US'),
            ('products_amazon_de', 'DE'),
            ('products_amazon_fr', 'FR'),
            ('products_amazon_ca', 'CA')
    LOOP
        -- Check if the table exists
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = tbl_name) THEN
            -- Check if country column exists
            IF NOT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = tbl_name AND column_name = 'country'
            ) THEN
                -- Add country column with appropriate default value
                EXECUTE format(
                    'ALTER TABLE %I ADD COLUMN country CHAR(2) NOT NULL DEFAULT %L',
                    tbl_name, country_code
                );
                
                -- Add index on country column
                EXECUTE format(
                    'CREATE INDEX IF NOT EXISTS idx_%I_country ON %I(country)',
                    tbl_name, tbl_name
                );
            END IF;
        END IF;
    END LOOP;
END $$;