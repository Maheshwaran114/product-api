-- Multi-Schema PostgreSQL Database Architecture with Country Tagging and GDPR Compliance
-- Created: April 30, 2025

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create schemas if they don't exist
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS agg;
CREATE SCHEMA IF NOT EXISTS aff;
CREATE SCHEMA IF NOT EXISTS social;
CREATE SCHEMA IF NOT EXISTS fin;
CREATE SCHEMA IF NOT EXISTS audit;

-- 2. Users Schema Implementation (GDPR-compliant)
-- Table: users.users
CREATE TABLE IF NOT EXISTS users.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email BYTEA NOT NULL, -- Encrypted email for GDPR compliance
  password_hash TEXT NOT NULL,
  consent_ts TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deletion_requested BOOLEAN NOT NULL DEFAULT FALSE,
  deletion_ts TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  country CHAR(2) NOT NULL DEFAULT 'US'
);

-- Add index for encrypted email search
CREATE INDEX IF NOT EXISTS idx_users_email_decrypted ON users.users
  USING btree (convert_to(decrypt(email, current_setting('app.encryption_key', true), 'aes'), 'UTF8'));

-- Add index for country code
CREATE INDEX IF NOT EXISTS idx_users_country ON users.users(country);

-- Table: users.user_consent (immutable consent history)
CREATE TABLE IF NOT EXISTS users.user_consent (
  user_id UUID NOT NULL,
  version INT NOT NULL,
  consent_ts TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  consent_text TEXT NOT NULL,
  PRIMARY KEY (user_id, version),
  CONSTRAINT fk_user_consent_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE
);

-- 3. Aggregate Schema Implementation
-- Table: agg.products (unified catalog)
CREATE TABLE IF NOT EXISTS agg.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL, -- e.g. "Amazon UK"
  external_id TEXT NOT NULL, -- ASIN or equivalent
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  detail_page_url TEXT,
  brand TEXT,
  browse_nodes TEXT[],
  price NUMERIC,
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  review_count INT,
  review_rating NUMERIC(3,2),
  retrieved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  country CHAR(2) NOT NULL DEFAULT 'US', -- Country market tag
  UNIQUE(source, external_id, country)
) PARTITION BY LIST (country);

-- Create country-specific partitions for product data
CREATE TABLE IF NOT EXISTS agg.products_us PARTITION OF agg.products 
  FOR VALUES IN ('US');
  
CREATE TABLE IF NOT EXISTS agg.products_gb PARTITION OF agg.products 
  FOR VALUES IN ('GB');
  
CREATE TABLE IF NOT EXISTS agg.products_ca PARTITION OF agg.products 
  FOR VALUES IN ('CA');
  
CREATE TABLE IF NOT EXISTS agg.products_de PARTITION OF agg.products 
  FOR VALUES IN ('DE');
  
CREATE TABLE IF NOT EXISTS agg.products_fr PARTITION OF agg.products 
  FOR VALUES IN ('FR');

-- Create a default partition for other countries
CREATE TABLE IF NOT EXISTS agg.products_other PARTITION OF agg.products DEFAULT;

-- Add browse_nodes GIN index to parent table (inherited by partitions)
CREATE INDEX IF NOT EXISTS idx_agg_products_browse_nodes ON agg.products USING GIN(browse_nodes);

-- Add indexes on each partition for better performance
CREATE INDEX IF NOT EXISTS idx_products_us_source_external_id ON agg.products_us(source, external_id);
CREATE INDEX IF NOT EXISTS idx_products_gb_source_external_id ON agg.products_gb(source, external_id);
CREATE INDEX IF NOT EXISTS idx_products_ca_source_external_id ON agg.products_ca(source, external_id);
CREATE INDEX IF NOT EXISTS idx_products_de_source_external_id ON agg.products_de(source, external_id);
CREATE INDEX IF NOT EXISTS idx_products_fr_source_external_id ON agg.products_fr(source, external_id);
CREATE INDEX IF NOT EXISTS idx_products_other_source_external_id ON agg.products_other(source, external_id);

-- 4. Affiliate Schema Implementation
-- Table: aff.affiliate_products - also partitioned by country
CREATE TABLE IF NOT EXISTS aff.affiliate_products (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL,
  avg_sale_value NUMERIC NOT NULL,
  commission_rate NUMERIC(5,2) NOT NULL,
  revenue_per_sale NUMERIC NOT NULL,
  sales_required_for_1000 INTEGER,
  visitors_req_1pct INTEGER,
  visitors_req_0_75pct INTEGER,
  visitors_req_0_05pct INTEGER,
  category TEXT,
  country CHAR(2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (id, country),
  CONSTRAINT fk_affiliate_products_product_id FOREIGN KEY (product_id) REFERENCES agg.products(id) ON DELETE CASCADE
) PARTITION BY LIST (country);

-- Create country-specific partitions
CREATE TABLE IF NOT EXISTS aff.affiliate_products_us PARTITION OF aff.affiliate_products
  FOR VALUES IN ('US');
  
CREATE TABLE IF NOT EXISTS aff.affiliate_products_gb PARTITION OF aff.affiliate_products
  FOR VALUES IN ('GB');
  
CREATE TABLE IF NOT EXISTS aff.affiliate_products_ca PARTITION OF aff.affiliate_products
  FOR VALUES IN ('CA');
  
CREATE TABLE IF NOT EXISTS aff.affiliate_products_de PARTITION OF aff.affiliate_products
  FOR VALUES IN ('DE');
  
CREATE TABLE IF NOT EXISTS aff.affiliate_products_fr PARTITION OF aff.affiliate_products
  FOR VALUES IN ('FR');
  
-- Create a default partition for other countries
CREATE TABLE IF NOT EXISTS aff.affiliate_products_other PARTITION OF aff.affiliate_products DEFAULT;

-- Add indexes to each partition for better performance
CREATE INDEX IF NOT EXISTS idx_aff_products_us_product_id ON aff.affiliate_products_us(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_gb_product_id ON aff.affiliate_products_gb(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_ca_product_id ON aff.affiliate_products_ca(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_de_product_id ON aff.affiliate_products_de(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_fr_product_id ON aff.affiliate_products_fr(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_other_product_id ON aff.affiliate_products_other(product_id);

-- 5. Social Schema Implementation
-- Table: social.reviews
CREATE TABLE IF NOT EXISTS social.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  product_id UUID NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_reviews_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_product_id FOREIGN KEY (product_id) REFERENCES agg.products(id) ON DELETE CASCADE
);

-- Table: social.questions
CREATE TABLE IF NOT EXISTS social.questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  product_id UUID NOT NULL,
  question TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_questions_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_questions_product_id FOREIGN KEY (product_id) REFERENCES agg.products(id) ON DELETE CASCADE
);

-- Table: social.price_alerts
CREATE TABLE IF NOT EXISTS social.price_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  product_id UUID NOT NULL,
  target_price NUMERIC NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_price_alerts_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_price_alerts_product_id FOREIGN KEY (product_id) REFERENCES agg.products(id) ON DELETE CASCADE
);

-- Table: social.chat_messages
CREATE TABLE IF NOT EXISTS social.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_chat_messages_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE
);

-- 6. Finance Schema Implementation
-- Table: fin.transactions
CREATE TABLE IF NOT EXISTS fin.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  affiliate_product_id UUID NOT NULL,
  amount NUMERIC NOT NULL,
  country CHAR(2) NOT NULL DEFAULT 'US',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_transactions_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE RESTRICT
);

-- Add country-based index for fin.transactions
CREATE INDEX IF NOT EXISTS idx_transactions_country ON fin.transactions(country);

-- Table: fin.payouts
CREATE TABLE IF NOT EXISTS fin.payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL,
  paid_to TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  country CHAR(2) NOT NULL DEFAULT 'US',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_payouts_transaction_id FOREIGN KEY (transaction_id) REFERENCES fin.transactions(id) ON DELETE RESTRICT
);

-- Add country-based index for fin.payouts
CREATE INDEX IF NOT EXISTS idx_payouts_country ON fin.payouts(country);

-- 7. Audit Schema Implementation
-- Table: audit.audit_logs (row-level change history)
CREATE TABLE IF NOT EXISTS audit.audit_logs (
  id BIGSERIAL PRIMARY KEY,
  schema_name TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  operation CHAR(1) NOT NULL CHECK (operation IN ('I', 'U', 'D')),
  changed_data JSONB NOT NULL,
  changed_by UUID,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  country CHAR(2),
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

-- Indexes for audit logs
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

CREATE INDEX IF NOT EXISTS idx_deletion_requests_status ON audit.deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_country ON audit.deletion_requests(country);

-- 8. Email encryption/decryption functions for GDPR compliance
CREATE OR REPLACE FUNCTION users.encrypt_email(p_email TEXT)
RETURNS BYTEA AS $$
BEGIN
  RETURN encrypt(convert_to(lower(p_email), 'UTF8'), current_setting('app.encryption_key', true), 'aes');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION users.decrypt_email(p_email_encrypted BYTEA)
RETURNS TEXT AS $$
BEGIN
  RETURN convert_from(decrypt(p_email_encrypted, current_setting('app.encryption_key', true), 'aes'), 'UTF8');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Trigger functions for audit logging
CREATE OR REPLACE FUNCTION audit.record_change()
RETURNS TRIGGER AS $$
DECLARE
  change_data JSONB;
  country_val CHAR(2);
BEGIN
  IF TG_OP = 'INSERT' THEN
    change_data = to_jsonb(NEW);
  ELSIF TG_OP = 'UPDATE' THEN
    change_data = jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW));
  ELSE
    change_data = to_jsonb(OLD);
  END IF;
  
  -- Try to extract country from the record
  IF TG_OP = 'DELETE' THEN
    IF OLD.country IS NOT NULL THEN
      country_val = OLD.country;
    END IF;
  ELSE
    IF NEW.country IS NOT NULL THEN
      country_val = NEW.country;
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
    CASE
      WHEN TG_OP = 'DELETE' THEN OLD.id
      ELSE NEW.id
    END,
    SUBSTRING(TG_OP, 1, 1),
    change_data,
    current_setting('app.current_user_id', TRUE)::UUID,
    country_val
  );
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 10. Timestamp trigger function for updated_at column
CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Create database roles and set permissions
-- Application roles
CREATE ROLE app_readonly;
CREATE ROLE app_readwrite;
CREATE ROLE app_admin;

-- Grant schema access
GRANT USAGE ON SCHEMA users, agg, aff, social, fin TO app_readonly, app_readwrite, app_admin;
GRANT USAGE ON SCHEMA audit TO app_admin;

-- Read permissions
GRANT SELECT ON ALL TABLES IN SCHEMA users, agg, aff, social, fin TO app_readonly, app_readwrite, app_admin;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA users, agg, aff, social, fin TO app_readonly, app_readwrite, app_admin;

-- Write permissions
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA users, agg, aff, social, fin TO app_readwrite, app_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA users, agg, aff, social, fin TO app_readwrite, app_admin;

-- Admin permissions
GRANT ALL PRIVILEGES ON SCHEMA audit TO app_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO app_admin;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA users, agg, aff, social, fin
GRANT SELECT ON TABLES TO app_readonly, app_readwrite, app_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA users, agg, aff, social, fin
GRANT INSERT, UPDATE, DELETE ON TABLES TO app_readwrite, app_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA users, agg, aff, social, fin
GRANT USAGE ON SEQUENCES TO app_readwrite, app_admin;

-- Create application users
CREATE USER api_service WITH PASSWORD 'secure_password_here';
CREATE USER reporting_service WITH PASSWORD 'secure_password_here';
CREATE USER admin_user WITH PASSWORD 'secure_password_here';

-- Assign roles to users
GRANT app_readwrite TO api_service;
GRANT app_readonly TO reporting_service;
GRANT app_admin TO admin_user;

-- 12. Add timestamp triggers to tables with updated_at columns
-- Users schema
CREATE TRIGGER update_users_timestamp
BEFORE UPDATE ON users.users
FOR EACH ROW
EXECUTE FUNCTION public.update_timestamp();

-- Affiliate schema
CREATE TRIGGER update_affiliate_products_timestamp
BEFORE UPDATE ON aff.affiliate_products
FOR EACH ROW
EXECUTE FUNCTION public.update_timestamp();

-- Social schema
CREATE TRIGGER update_reviews_timestamp
BEFORE UPDATE ON social.reviews
FOR EACH ROW
EXECUTE FUNCTION public.update_timestamp();

-- 13. Add audit triggers to track all data changes
-- Users schema
CREATE TRIGGER audit_users_changes
AFTER INSERT OR UPDATE OR DELETE ON users.users
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

CREATE TRIGGER audit_user_consent_changes
AFTER INSERT OR UPDATE OR DELETE ON users.user_consent
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

-- Aggregate schema
CREATE TRIGGER audit_products_changes
AFTER INSERT OR UPDATE OR DELETE ON agg.products
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

-- Affiliate schema
CREATE TRIGGER audit_affiliate_products_changes
AFTER INSERT OR UPDATE OR DELETE ON aff.affiliate_products
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

-- Social schema
CREATE TRIGGER audit_reviews_changes
AFTER INSERT OR UPDATE OR DELETE ON social.reviews
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

CREATE TRIGGER audit_questions_changes
AFTER INSERT OR UPDATE OR DELETE ON social.questions
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

CREATE TRIGGER audit_price_alerts_changes
AFTER INSERT OR UPDATE OR DELETE ON social.price_alerts
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

CREATE TRIGGER audit_chat_messages_changes
AFTER INSERT OR UPDATE OR DELETE ON social.chat_messages
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

-- Finance schema
CREATE TRIGGER audit_transactions_changes
AFTER INSERT OR UPDATE OR DELETE ON fin.transactions
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

CREATE TRIGGER audit_payouts_changes
AFTER INSERT OR UPDATE OR DELETE ON fin.payouts
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();

-- Audit schema
CREATE TRIGGER audit_deletion_requests_changes
AFTER INSERT OR UPDATE OR DELETE ON audit.deletion_requests
FOR EACH ROW
EXECUTE FUNCTION audit.record_change();