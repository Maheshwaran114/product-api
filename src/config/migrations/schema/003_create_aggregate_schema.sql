-- 003_create_aggregate_schema.sql
-- Aggregate products schema with country-based partitioning
-- Created: May 1, 2025

-- Table: agg.products (unified catalog with partitioning by country)
CREATE TABLE IF NOT EXISTS agg.products (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
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
  -- For partitioned tables, primary key must include the partitioning column
  PRIMARY KEY (id, country),
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