-- 009_create_timestamp_triggers.sql
-- Add triggers to automatically update the updated_at column
-- Created: May 2, 2025

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp triggers to all tables with updated_at columns in users schema
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'users'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_timestamp_trigger ON users.%I;
            CREATE TRIGGER update_timestamp_trigger
            BEFORE UPDATE ON users.%I
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
        ', r.table_name, r.table_name);
    END LOOP;
END;
$$;

-- Apply timestamp triggers to all tables with updated_at columns in agg schema
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'agg'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_timestamp_trigger ON agg.%I;
            CREATE TRIGGER update_timestamp_trigger
            BEFORE UPDATE ON agg.%I
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
        ', r.table_name, r.table_name);
    END LOOP;
END;
$$;

-- Apply timestamp triggers to all tables with updated_at columns in aff schema
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'aff'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_timestamp_trigger ON aff.%I;
            CREATE TRIGGER update_timestamp_trigger
            BEFORE UPDATE ON aff.%I
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
        ', r.table_name, r.table_name);
    END LOOP;
END;
$$;

-- Apply timestamp triggers to all tables with updated_at columns in social schema
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'social'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_timestamp_trigger ON social.%I;
            CREATE TRIGGER update_timestamp_trigger
            BEFORE UPDATE ON social.%I
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
        ', r.table_name, r.table_name);
    END LOOP;
END;
$$;

-- Apply timestamp triggers to all tables with updated_at columns in fin schema
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'fin'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_timestamp_trigger ON fin.%I;
            CREATE TRIGGER update_timestamp_trigger
            BEFORE UPDATE ON fin.%I
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
        ', r.table_name, r.table_name);
    END LOOP;
END;
$$;

COMMENT ON FUNCTION update_timestamp() IS 'Function to automatically update updated_at timestamps for GDPR and data freshness tracking';