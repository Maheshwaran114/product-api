-- Data Migration Script to populate our multi-schema architecture
-- Created: April 30, 2025

-- This script contains data migrations and sample data to demonstrate the functionality
-- of our multi-schema PostgreSQL database architecture with GDPR compliance

-- Start a transaction for atomicity
BEGIN;

-- Set encryption key for email encryption
SET app.encryption_key = 'temp_key_for_development_only';

-- 1. Sample Users with encrypted emails (users schema)
INSERT INTO users.users (id, email, password_hash, country)
VALUES
  (gen_random_uuid(), users.encrypt_email('john.doe@example.com'), 
   crypt('securepassword123', gen_salt('bf')), 'US'),
  (gen_random_uuid(), users.encrypt_email('jane.smith@example.co.uk'), 
   crypt('ukpassword456', gen_salt('bf')), 'GB'),
  (gen_random_uuid(), users.encrypt_email('hans.mueller@example.de'), 
   crypt('germanpass789', gen_salt('bf')), 'DE')
ON CONFLICT DO NOTHING;

-- 2. Consent records for each user (from users table)
INSERT INTO users.user_consent (user_id, version, consent_text)
SELECT 
  id, 
  1, 
  'I consent to the collection and processing of my personal data according to the Privacy Policy v1.0.'
FROM users.users
ON CONFLICT DO NOTHING;

-- 3. Migrate existing US Amazon products to agg.products (if they exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products_amazon_us') THEN
    INSERT INTO agg.products (
      source, external_id, title, description, brand, price, 
      currency, image_url, detail_page_url, review_count, 
      review_rating, retrieved_at, country
    )
    SELECT 
      'Amazon US', 
      external_id,
      title,
      description,
      brand,
      price,
      COALESCE(currency, 'USD'),
      image_url,
      product_url,
      total_reviews,
      rating,
      retrieved_at,
      'US'
    FROM products_amazon_us
    ON CONFLICT (source, external_id) DO NOTHING;
  END IF;
END $$;

-- 4. Migrate existing UK Amazon products to agg.products (if they exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products_amazon_uk') THEN
    INSERT INTO agg.products (
      source, external_id, title, description, brand, price, 
      currency, image_url, detail_page_url, review_count, 
      review_rating, retrieved_at, country
    )
    SELECT 
      'Amazon UK', 
      external_id,
      title,
      description,
      brand,
      price,
      COALESCE(currency, 'GBP'),
      image_url,
      product_url,
      total_reviews,
      rating,
      retrieved_at,
      'GB'
    FROM products_amazon_uk
    ON CONFLICT (source, external_id) DO NOTHING;
  END IF;
END $$;

-- 5. Insert sample affiliate metrics for some products (aff schema)
INSERT INTO aff.affiliate_products (
  product_id, avg_sale_value, commission_rate, revenue_per_sale,
  sales_required_for_1000, visitors_req_1pct, visitors_req_0_75pct,
  visitors_req_0_05pct, category, country
)
SELECT 
  id,
  price * 0.9,                  -- avg_sale_value (90% of price)
  CASE 
    WHEN price > 1000 THEN 3.5  -- Higher ticket items have lower commission
    WHEN price > 500 THEN 5.0
    WHEN price > 100 THEN 7.0
    ELSE 10.0
  END,                          -- commission_rate
  price * 0.9 * CASE 
    WHEN price > 1000 THEN 0.035
    WHEN price > 500 THEN 0.05
    WHEN price > 100 THEN 0.07
    ELSE 0.1
  END,                          -- revenue_per_sale
  CEIL(1000 / (price * 0.9 * CASE 
    WHEN price > 1000 THEN 0.035
    WHEN price > 500 THEN 0.05
    WHEN price > 100 THEN 0.07
    ELSE 0.1
  END)),                        -- sales_required_for_1000
  CEIL(100 / 1),                -- visitors_req_1pct (assuming 1% conversion)
  CEIL(100 / 0.75),             -- visitors_req_0_75pct
  CEIL(100 / 0.05),             -- visitors_req_0_05pct
  CASE 
    WHEN (title ILIKE '%laptop%' OR brand ILIKE '%apple%') THEN 'Electronics'
    WHEN title ILIKE '%book%' THEN 'Books'
    ELSE 'General'
  END,                          -- category
  country                       -- country (same as product)
FROM agg.products
WHERE id IN (
  SELECT id FROM agg.products ORDER BY RANDOM() LIMIT 10
)
ON CONFLICT DO NOTHING;

-- 6. Insert sample social engagement data (reviews, questions, price alerts)
-- Get sample user IDs
DO $$
DECLARE
  user_us_id UUID;
  user_gb_id UUID;
  product_us_id UUID;
  product_gb_id UUID;
BEGIN
  -- Get US and UK user IDs
  SELECT id INTO user_us_id FROM users.users WHERE country = 'US' LIMIT 1;
  SELECT id INTO user_gb_id FROM users.users WHERE country = 'GB' LIMIT 1;
  
  -- Get US and UK product IDs
  SELECT id INTO product_us_id FROM agg.products WHERE country = 'US' LIMIT 1;
  SELECT id INTO product_gb_id FROM agg.products WHERE country = 'GB' LIMIT 1;
  
  -- Only proceed if we have both users and products
  IF user_us_id IS NOT NULL AND user_gb_id IS NOT NULL AND 
     product_us_id IS NOT NULL AND product_gb_id IS NOT NULL THEN
    
    -- Add reviews (US user reviews US product, UK user reviews UK product)
    INSERT INTO social.reviews (user_id, product_id, rating, review_text)
    VALUES 
      (user_us_id, product_us_id, 4, 'Great product for the price. Fast shipping and as described.'),
      (user_gb_id, product_gb_id, 5, 'Absolutely brilliant. Would recommend to anyone.');
    
    -- Add questions
    INSERT INTO social.questions (user_id, product_id, question)
    VALUES
      (user_us_id, product_us_id, 'Does this product work with 220V power?'),
      (user_gb_id, product_gb_id, 'How long is the warranty?');
    
    -- Add price alerts
    INSERT INTO social.price_alerts (user_id, product_id, target_price)
    VALUES
      (user_us_id, product_us_id, 
       (SELECT price * 0.9 FROM agg.products WHERE id = product_us_id)),
      (user_gb_id, product_gb_id, 
       (SELECT price * 0.85 FROM agg.products WHERE id = product_gb_id));
  END IF;
END $$;

-- 7. Insert sample financial transactions
DO $$
DECLARE
  user_id UUID;
  aff_product_id UUID;
BEGIN
  -- Get a user and affiliate product
  SELECT u.id INTO user_id FROM users.users u LIMIT 1;
  SELECT a.id INTO aff_product_id FROM aff.affiliate_products a LIMIT 1;
  
  IF user_id IS NOT NULL AND aff_product_id IS NOT NULL THEN
    -- Create a transaction
    INSERT INTO fin.transactions (user_id, affiliate_product_id, amount)
    VALUES (user_id, aff_product_id, 
            (SELECT revenue_per_sale FROM aff.affiliate_products WHERE id = aff_product_id));
    
    -- Create a payout for the transaction
    INSERT INTO fin.payouts (transaction_id, paid_to, amount, status)
    SELECT 
      id, 
      'PayPal: ' || users.decrypt_email(u.email),
      t.amount,
      'completed'
    FROM fin.transactions t
    JOIN users.users u ON t.user_id = u.id
    ORDER BY t.created_at DESC
    LIMIT 1;
  END IF;
END $$;

-- 8. Create sample audit log entries
INSERT INTO audit.audit_logs (schema_name, table_name, record_id, operation, changed_data, changed_by)
SELECT 'users', 'users', id, 'I', 
  jsonb_build_object(
    'email', 'ENCRYPTED',
    'country', country,
    'created_at', created_at::text
  ),
  id
FROM users.users
WHERE id IN (SELECT id FROM users.users LIMIT 3);

-- 9. Create a sample deletion request (for GDPR demo)
DO $$
DECLARE
  sample_user_id UUID;
BEGIN
  -- Get a sample user for deletion request
  SELECT id INTO sample_user_id FROM users.users ORDER BY RANDOM() LIMIT 1;
  
  IF sample_user_id IS NOT NULL THEN
    -- Create deletion request
    INSERT INTO audit.deletion_requests (user_id, status)
    VALUES (sample_user_id, 'pending');
    
    -- Update user record to mark deletion requested
    UPDATE users.users
    SET deletion_requested = TRUE
    WHERE id = sample_user_id;
    
    -- Add audit log entry for this action
    INSERT INTO audit.audit_logs 
      (schema_name, table_name, record_id, operation, changed_data, changed_by)
    VALUES
      ('users', 'users', sample_user_id, 'U', 
       jsonb_build_object('deletion_requested', true),
       sample_user_id);
  END IF;
END $$;

COMMIT;