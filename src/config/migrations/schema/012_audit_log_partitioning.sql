-- 012_audit_log_partitioning.sql
-- Implement partitioning for audit logs with retention policy
-- Created: May 2, 2025

-- Ensure audit schema exists
CREATE SCHEMA IF NOT EXISTS audit;

-- Create partitioned audit log table
CREATE TABLE IF NOT EXISTS audit.partitioned_change_log (
    id BIGSERIAL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_data JSONB NOT NULL,
    changed_by TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, changed_at)
) PARTITION BY RANGE (changed_at);

-- Create monthly partitions for the current year and next year
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('year', CURRENT_DATE);
    end_date DATE := DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '2 years';
    month_date DATE;
    partition_name TEXT;
    start_range TEXT;
    end_range TEXT;
BEGIN
    month_date := start_date;
    
    WHILE month_date < end_date LOOP
        partition_name := 'audit_log_p' || TO_CHAR(month_date, 'YYYYMM');
        start_range := TO_CHAR(month_date, 'YYYY-MM-DD');
        month_date := month_date + INTERVAL '1 month';
        end_range := TO_CHAR(month_date, 'YYYY-MM-DD');
        
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS audit.%I
            PARTITION OF audit.partitioned_change_log
            FOR VALUES FROM (%L) TO (%L)
        ', partition_name, start_range, end_range);
        
        -- Set appropriate permissions
        EXECUTE format('
            GRANT SELECT ON audit.%I TO app_admin, gdpr_officer
        ', partition_name);
    END LOOP;
END
$$;

-- Function to create future partitions
CREATE OR REPLACE FUNCTION audit.create_future_partition()
RETURNS void AS $$
DECLARE
    future_date DATE;
    partition_name TEXT;
    start_range TEXT;
    end_range TEXT;
BEGIN
    -- Create partition for 3 months ahead
    future_date := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '3 months');
    partition_name := 'audit_log_p' || TO_CHAR(future_date, 'YYYYMM');
    start_range := TO_CHAR(future_date, 'YYYY-MM-DD');
    future_date := future_date + INTERVAL '1 month';
    end_range := TO_CHAR(future_date, 'YYYY-MM-DD');
    
    -- Only create if it doesn't exist yet
    IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                  WHERE c.relname = partition_name AND n.nspname = 'audit') THEN
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS audit.%I
            PARTITION OF audit.partitioned_change_log
            FOR VALUES FROM (%L) TO (%L)
        ', partition_name, start_range, end_range);
        
        -- Set appropriate permissions
        EXECUTE format('
            GRANT SELECT ON audit.%I TO app_admin, gdpr_officer
        ', partition_name);
        
        RAISE NOTICE 'Created new audit log partition: %', partition_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Schedule partition creation with a cron job
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Add a monthly job to create future partitions
SELECT cron.schedule('0 0 1 * *', 'SELECT audit.create_future_partition()');

-- Function to enforce retention policy (drop old partitions)
CREATE OR REPLACE FUNCTION audit.enforce_retention_policy(retention_months INTEGER)
RETURNS void AS $$
DECLARE
    cutoff_date DATE := DATE_TRUNC('month', CURRENT_DATE - (retention_months || ' months')::INTERVAL);
    partition_name TEXT;
    partition_date DATE;
BEGIN
    FOR partition_name IN 
        SELECT c.relname 
        FROM pg_class c 
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'audit' 
        AND c.relname LIKE 'audit_log_p%'
        ORDER BY c.relname
    LOOP
        -- Extract date from partition name (format: audit_log_pYYYYMM)
        BEGIN
            partition_date := TO_DATE(SUBSTRING(partition_name FROM 11 FOR 6), 'YYYYMM');
            
            -- Drop partition if it's older than the retention period
            IF partition_date < cutoff_date THEN
                EXECUTE format('DROP TABLE IF EXISTS audit.%I', partition_name);
                RAISE NOTICE 'Dropped audit partition: % (date: %)', partition_name, partition_date;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not parse date from partition: %', partition_name;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule retention policy enforcement (run weekly, keep 24 months of data)
SELECT cron.schedule('0 1 * * 0', 'SELECT audit.enforce_retention_policy(24)');

-- Create function to record changes to the partitioned table
CREATE OR REPLACE FUNCTION audit.record_partitioned_change()
RETURNS TRIGGER AS $$
DECLARE
    data JSONB;
    excluded_cols TEXT[] := ARRAY[]::TEXT[];
BEGIN
    IF TG_OP = 'INSERT' THEN
        data := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        data := jsonb_build_object(
            'old', to_jsonb(OLD),
            'new', to_jsonb(NEW)
        );
    ELSIF TG_OP = 'DELETE' THEN
        data := to_jsonb(OLD);
    END IF;

    INSERT INTO audit.partitioned_change_log(
        table_name,
        operation,
        changed_data,
        changed_by
    ) VALUES (
        TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
        TG_OP,
        data,
        current_setting('app.current_user', true)
    );
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Note: Apply this to critical tables only to avoid performance impact
CREATE TRIGGER users_audit_partitioned_trigger
AFTER INSERT OR UPDATE OR DELETE ON users.users
FOR EACH ROW EXECUTE FUNCTION audit.record_partitioned_change();

COMMENT ON FUNCTION audit.record_partitioned_change() IS 'Function to record changes to partitioned audit log table';
COMMENT ON FUNCTION audit.create_future_partition() IS 'Creates future partitions for audit logs';
COMMENT ON FUNCTION audit.enforce_retention_policy(INTEGER) IS 'Enforces the retention policy by dropping old audit log partitions';