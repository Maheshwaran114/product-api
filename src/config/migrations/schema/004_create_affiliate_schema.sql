-- 004_create_affiliate_schema.sql
-- Affiliate products schema with country-based partitioning
-- Created: May 1, 2025

-- Table: aff.affiliate_products - partitioned by country
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
  -- Modified foreign key to include both product_id and country
  CONSTRAINT fk_affiliate_products_product_id FOREIGN KEY (product_id, country) 
    REFERENCES agg.products(id, country) ON DELETE CASCADE
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

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_aff_products_us_product_id ON aff.affiliate_products_us(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_gb_product_id ON aff.affiliate_products_gb(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_ca_product_id ON aff.affiliate_products_ca(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_de_product_id ON aff.affiliate_products_de(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_fr_product_id ON aff.affiliate_products_fr(product_id);
CREATE INDEX IF NOT EXISTS idx_aff_products_other_product_id ON aff.affiliate_products_other(product_id);