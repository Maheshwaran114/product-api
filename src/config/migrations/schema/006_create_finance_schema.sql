-- 006_create_finance_schema.sql
-- Finance schema for transactions and payouts
-- Created: May 1, 2025

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

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_fin_transactions_user_id ON fin.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_country ON fin.transactions(country);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_created_at ON fin.transactions(created_at);

-- Table: fin.payouts
CREATE TABLE IF NOT EXISTS fin.payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL,
  paid_to TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  country CHAR(2) NOT NULL DEFAULT 'US',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  CONSTRAINT fk_payouts_transaction_id FOREIGN KEY (transaction_id) REFERENCES fin.transactions(id) ON DELETE RESTRICT
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_fin_payouts_transaction_id ON fin.payouts(transaction_id);
CREATE INDEX IF NOT EXISTS idx_fin_payouts_status ON fin.payouts(status);
CREATE INDEX IF NOT EXISTS idx_fin_payouts_country ON fin.payouts(country);
CREATE INDEX IF NOT EXISTS idx_fin_payouts_created_at ON fin.payouts(created_at);