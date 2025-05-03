-- 007_create_audit_schema.sql
-- Audit schema for tracking changes and GDPR compliance
-- Created: May 1, 2025

-- Table: audit.audit_logs (row-level change history with time-based partitioning)
CREATE TABLE IF NOT EXISTS audit.audit_logs (
  id BIGSERIAL NOT NULL,
  schema_name TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  operation CHAR(1) NOT NULL CHECK (operation IN ('I', 'U', 'D')),
  changed_data JSONB NOT NULL,
  changed_by UUID,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  country CHAR(2),
  -- Include partition column (changed_at) in the primary key for partitioned tables
  PRIMARY KEY (id, changed_at),
  CONSTRAINT fk_audit_logs_changed_by FOREIGN KEY (changed_by) REFERENCES users.users(id) ON DELETE SET NULL
) PARTITION BY RANGE (changed_at);

-- Create time-based partitioning for audit logs (quarterly partitions)
CREATE TABLE IF NOT EXISTS audit.audit_logs_2025q1 PARTITION OF audit.audit_logs
  FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
  
CREATE TABLE IF NOT EXISTS audit.audit_logs_2025q2 PARTITION OF audit.audit_logs
  FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');
  
CREATE TABLE IF NOT EXISTS audit.audit_logs_2025q3 PARTITION OF audit.audit_logs
  FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');
  
CREATE TABLE IF NOT EXISTS audit.audit_logs_2025q4 PARTITION OF audit.audit_logs
  FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_record ON audit.audit_logs(schema_name, table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_changed_at ON audit.audit_logs(changed_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_country ON audit.audit_logs(country);

-- Table: audit.deletion_requests ("right to be forgotten" tracking)
CREATE TABLE IF NOT EXISTS audit.deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  request_ts TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'pending',
  processed_ts TIMESTAMPTZ,
  country CHAR(2),
  CONSTRAINT fk_deletion_requests_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_deletion_requests_status ON audit.deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_country ON audit.deletion_requests(country);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_user_id ON audit.deletion_requests(user_id);

-- Audit trigger function to automatically record changes
CREATE OR REPLACE FUNCTION audit.record_change()
RETURNS TRIGGER AS $$
DECLARE
  change_data JSONB;
  country_val CHAR(2);
  has_country BOOLEAN;
  has_id BOOLEAN;
  record_id UUID;
  record_obj JSONB;
BEGIN
  -- Create the changed data object
  IF TG_OP = 'INSERT' THEN
    change_data = to_jsonb(NEW);
    record_obj = to_jsonb(NEW);
  ELSIF TG_OP = 'UPDATE' THEN
    change_data = jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW));
    record_obj = to_jsonb(NEW);
  ELSE -- DELETE
    change_data = to_jsonb(OLD);
    record_obj = to_jsonb(OLD);
  END IF;

  -- Check if the table has an id column
  has_id := EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = TG_TABLE_SCHEMA 
      AND table_name = TG_TABLE_NAME 
      AND column_name = 'id'
  );
  
  -- Try to get the record id if it exists
  IF has_id THEN
    IF record_obj ? 'id' THEN
      record_id = (record_obj->>'id')::UUID;
    END IF;
  END IF;
  
  -- If we don't have a record_id, generate one
  IF record_id IS NULL THEN
    record_id = gen_random_uuid();
  END IF;
  
  -- Check if table has country column
  has_country := EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = TG_TABLE_SCHEMA 
      AND table_name = TG_TABLE_NAME 
      AND column_name = 'country'
  );
  
  -- Try to extract country if it exists
  IF has_country THEN
    IF record_obj ? 'country' THEN
      country_val = record_obj->>'country';
    END IF;
  END IF;
  
  INSERT INTO audit.audit_logs(
    schema_name,
    table_name,
    record_id,
    operation,
    changed_data,
    changed_by,
    country
  ) VALUES (
    TG_TABLE_SCHEMA,
    TG_TABLE_NAME,
    record_id,
    SUBSTRING(TG_OP, 1, 1),
    change_data,
    -- Allow NULL for current_user_id in case it's not set
    NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID,
    country_val
  );
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;