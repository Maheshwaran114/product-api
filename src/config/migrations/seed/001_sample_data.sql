-- 001_sample_data.sql
-- Sample data for demonstration purposes only
-- Created: May 1, 2025

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
   crypt('germanpass789', gen_salt('bf')), 'DE'),
  (gen_random_uuid(), users.encrypt_email('pierre.martin@example.fr'), 
   crypt('frenchpass101', gen_salt('bf')), 'FR'),
  (gen_random_uuid(), users.encrypt_email('emily.scott@example.ca'), 
   crypt('canadapass202', gen_salt('bf')), 'CA')
ON CONFLICT DO NOTHING;

-- 2. Consent records for each user (from users table)
INSERT INTO users.user_consent (user_id, version, consent_text)
SELECT 
  id, 
  1, 
  'I consent to the collection and processing of my personal data according to the Privacy Policy v1.0.'
FROM users.users
ON CONFLICT DO NOTHING;

-- 3. Sample products if none exist in the aggregate products table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM agg.products LIMIT 1) THEN
    -- Insert sample US products
    INSERT INTO agg.products (
      source, external_id, title, description, brand, 
      price, currency, image_url, detail_page_url, country
    ) VALUES
      ('Amazon US', 'B08X12345', 'MacBook Pro 16-inch', 'Latest Apple MacBook Pro with M1 chip', 'Apple', 
       2399.00, 'USD', 'https://example.com/macbook.jpg', 'https://amazon.com/dp/B08X12345', 'US'),
      ('Amazon US', 'B08X67890', 'iPhone 13 Pro', 'Apple iPhone with A15 Bionic chip', 'Apple', 
       999.00, 'USD', 'https://example.com/iphone.jpg', 'https://amazon.com/dp/B08X67890', 'US'),
      ('Walmart US', 'WM12345', 'Samsung 65" QLED TV', '4K Smart TV with QLED display', 'Samsung', 
       1299.00, 'USD', 'https://example.com/tv.jpg', 'https://walmart.com/ip/WM12345', 'US');
       
    -- Insert sample UK products
    INSERT INTO agg.products (
      source, external_id, title, description, brand, 
      price, currency, image_url, detail_page_url, country
    ) VALUES
      ('Amazon UK', 'B08Y12345', 'MacBook Pro 16-inch', 'Latest Apple MacBook Pro with M1 chip', 'Apple', 
       2199.00, 'GBP', 'https://example.com/macbook.jpg', 'https://amazon.co.uk/dp/B08Y12345', 'GB'),
      ('John Lewis UK', 'JL67890', 'Dyson V11 Vacuum', 'Cordless vacuum cleaner', 'Dyson', 
       499.00, 'GBP', 'https://example.com/dyson.jpg', 'https://johnlewis.com/dyson-v11', 'GB');
       
    -- Insert sample CA (Canada) products
    INSERT INTO agg.products (
      source, external_id, title, description, brand, 
      price, currency, image_url, detail_page_url, country
    ) VALUES
      ('Amazon CA', 'B08Z12345', 'MacBook Pro 16-inch', 'Latest Apple MacBook Pro with M1 chip', 'Apple', 
       2999.00, 'CAD', 'https://example.com/macbook.jpg', 'https://amazon.ca/dp/B08Z12345', 'CA'),
      ('BestBuy CA', 'BB67890', 'Sony PlayStation 5', 'Next-gen gaming console', 'Sony', 
       599.00, 'CAD', 'https://example.com/ps5.jpg', 'https://bestbuy.ca/en-ca/product/sony-ps5', 'CA');
  END IF;
END $$;

-- 4. Sample affiliate metrics for the products
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM aff.affiliate_products LIMIT 1) THEN
    INSERT INTO aff.affiliate_products (
      product_id, avg_sale_value, commission_rate, revenue_per_sale,
      sales_required_for_1000, visitors_req_1pct, visitors_req_0_75pct,
      visitors_req_0_05pct, category, country
    )
    SELECT 
      id,                           -- product_id
      price * 0.9,                  -- avg_sale_value (90% of price)
      CASE 
        WHEN price > 1000 THEN 3.5  -- Higher ticket items have lower commission
        WHEN price > 500 THEN 5.0
        WHEN price > 100 THEN 7.0
        ELSE 10.0
      END,                          -- commission_rate
      (price * 0.9) * 
      (CASE 
        WHEN price > 1000 THEN 0.035
        WHEN price > 500 THEN 0.05
        WHEN price > 100 THEN 0.07
        ELSE 0.1
      END),                         -- revenue_per_sale
      CEIL(1000 / (price * 0.9 * 
      (CASE 
        WHEN price > 1000 THEN 0.035
        WHEN price > 500 THEN 0.05
        WHEN price > 100 THEN 0.07
        ELSE 0.1
      END))),                       -- sales_required_for_1000
      100,                          -- visitors_req_1pct (assuming 1% conversion)
      133,                          -- visitors_req_0_75pct
      2000,                         -- visitors_req_0_05pct
      CASE 
        WHEN (title ILIKE '%macbook%' OR title ILIKE '%iphone%') THEN 'Electronics'
        WHEN title ILIKE '%vacuum%' THEN 'Home Appliances'
        WHEN title ILIKE '%tv%' THEN 'TVs & Entertainment'
        WHEN title ILIKE '%playstation%' OR title ILIKE '%ps5%' THEN 'Gaming'
        ELSE 'General'
      END,                          -- category
      country                       -- country (same as product)
    FROM agg.products;
  END IF;
END $$;

-- 5. Sample social engagement data
DO $$
DECLARE
  us_user_id UUID;
  gb_user_id UUID;
  ca_user_id UUID;
  us_product_id UUID;
  gb_product_id UUID;
  ca_product_id UUID;
BEGIN
  -- Get user IDs
  SELECT id INTO us_user_id FROM users.users WHERE country = 'US' LIMIT 1;
  SELECT id INTO gb_user_id FROM users.users WHERE country = 'GB' LIMIT 1;
  SELECT id INTO ca_user_id FROM users.users WHERE country = 'CA' LIMIT 1;
  
  -- Get product IDs
  SELECT id INTO us_product_id FROM agg.products WHERE country = 'US' LIMIT 1;
  SELECT id INTO gb_product_id FROM agg.products WHERE country = 'GB' LIMIT 1;
  SELECT id INTO ca_product_id FROM agg.products WHERE country = 'CA' LIMIT 1;
  
  -- Only proceed if we have both users and products
  IF us_user_id IS NOT NULL AND gb_user_id IS NOT NULL AND 
     us_product_id IS NOT NULL AND gb_product_id IS NOT NULL THEN
    
    -- Add reviews (users review products from their country)
    -- Include country column to fix not-null constraint issue
    IF NOT EXISTS (SELECT 1 FROM social.reviews LIMIT 1) THEN
      INSERT INTO social.reviews (user_id, product_id, rating, review_text, country)
      VALUES 
        (us_user_id, us_product_id, 4, 'Great product for the price. Fast shipping and as described.', 'US'),
        (gb_user_id, gb_product_id, 5, 'Absolutely brilliant. Would recommend to anyone.', 'GB');
        
      -- Add Canada review if we have a Canadian user and product
      IF ca_user_id IS NOT NULL AND ca_product_id IS NOT NULL THEN
        INSERT INTO social.reviews (user_id, product_id, rating, review_text, country)
        VALUES (ca_user_id, ca_product_id, 4, 'Excellent product from Canada. Fast shipping and good customer service.', 'CA');
      END IF;
    END IF;
    
    -- Add questions with country column
    IF NOT EXISTS (SELECT 1 FROM social.questions LIMIT 1) THEN
      INSERT INTO social.questions (user_id, product_id, question, country)
      VALUES
        (us_user_id, us_product_id, 'Does this product work with 220V power?', 'US'),
        (gb_user_id, gb_product_id, 'How long is the warranty?', 'GB');
        
      -- Add Canada question if we have a Canadian user and product
      IF ca_user_id IS NOT NULL AND ca_product_id IS NOT NULL THEN
        INSERT INTO social.questions (user_id, product_id, question, country)
        VALUES (ca_user_id, ca_product_id, 'Is this compatible with Canadian outlets?', 'CA');
      END IF;
    END IF;
    
    -- Add price alerts with country column
    IF NOT EXISTS (SELECT 1 FROM social.price_alerts LIMIT 1) THEN
      INSERT INTO social.price_alerts (user_id, product_id, target_price, country)
      VALUES
        (us_user_id, us_product_id, 
         (SELECT price * 0.9 FROM agg.products WHERE id = us_product_id), 'US'),
        (gb_user_id, gb_product_id, 
         (SELECT price * 0.85 FROM agg.products WHERE id = gb_product_id), 'GB');
         
      -- Add Canada price alert if we have a Canadian user and product
      IF ca_user_id IS NOT NULL AND ca_product_id IS NOT NULL THEN
        INSERT INTO social.price_alerts (user_id, product_id, target_price, country)
        VALUES (ca_user_id, ca_product_id, 
               (SELECT price * 0.88 FROM agg.products WHERE id = ca_product_id), 'CA');
      END IF;
    END IF;
  END IF;
END $$;

-- 6. Sample GDPR deletion request (for demo purposes)
DO $$
DECLARE
  sample_user_id UUID;
BEGIN
  -- Get a sample user for deletion request
  SELECT id INTO sample_user_id FROM users.users ORDER BY RANDOM() LIMIT 1;
  
  -- Only proceed if we have a user
  IF sample_user_id IS NOT NULL AND 
     NOT EXISTS (SELECT 1 FROM audit.deletion_requests LIMIT 1) THEN
    -- Create deletion request
    INSERT INTO audit.deletion_requests (user_id, status)
    VALUES (sample_user_id, 'pending');
    
    -- Update user record to mark deletion requested
    UPDATE users.users
    SET deletion_requested = TRUE
    WHERE id = sample_user_id;
    
    -- Set the current user for audit purposes
    PERFORM set_config('app.current_user_id', sample_user_id::text, true);
  END IF;
END $$;

COMMIT;