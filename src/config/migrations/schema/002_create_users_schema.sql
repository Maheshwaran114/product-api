-- 002_create_users_schema.sql
-- Users schema with GDPR-compliant user management
-- Created: May 1, 2025

-- Make sure pgcrypto is installed
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Set a default encryption key if not provided
DO $$
BEGIN
    BEGIN
        PERFORM set_config('app.encryption_key', current_setting('app.encryption_key'), false);
    EXCEPTION WHEN OTHERS THEN
        PERFORM set_config('app.encryption_key', 'temp_key_for_development_only', true);
    END;
END $$;

-- Email encryption/decryption functions for GDPR compliance
CREATE OR REPLACE FUNCTION users.encrypt_email(p_email TEXT)
RETURNS BYTEA AS $$
BEGIN
  RETURN pgp_sym_encrypt(lower(p_email), current_setting('app.encryption_key'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION users.decrypt_email(p_email_encrypted BYTEA)
RETURNS TEXT AS $$
BEGIN
  RETURN pgp_sym_decrypt(p_email_encrypted, current_setting('app.encryption_key'));
EXCEPTION WHEN OTHERS THEN
  RETURN NULL; -- Return null on decryption failure
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Table: users.users (GDPR-compliant)
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