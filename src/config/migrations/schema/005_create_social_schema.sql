-- 005_create_social_schema.sql
-- Social engagement schema (reviews, questions, etc.)
-- Created: May 1, 2025

-- Table: social.reviews
CREATE TABLE IF NOT EXISTS social.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  product_id UUID NOT NULL,
  country CHAR(2) NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_reviews_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_product_id FOREIGN KEY (product_id) REFERENCES agg.products(id) ON DELETE CASCADE
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_social_reviews_user_id ON social.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_social_reviews_product_id ON social.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_social_reviews_country ON social.reviews(country);

-- Table: social.questions
CREATE TABLE IF NOT EXISTS social.questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  product_id UUID NOT NULL,
  country CHAR(2) NOT NULL,
  question TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_questions_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_questions_product_id FOREIGN KEY (product_id) REFERENCES agg.products(id) ON DELETE CASCADE
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_social_questions_user_id ON social.questions(user_id);
CREATE INDEX IF NOT EXISTS idx_social_questions_product_id ON social.questions(product_id);
CREATE INDEX IF NOT EXISTS idx_social_questions_country ON social.questions(country);

-- Table: social.price_alerts
CREATE TABLE IF NOT EXISTS social.price_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  product_id UUID NOT NULL,
  country CHAR(2) NOT NULL,
  target_price NUMERIC NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_price_alerts_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_price_alerts_product_id FOREIGN KEY (product_id) REFERENCES agg.products(id) ON DELETE CASCADE
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_social_price_alerts_user_id ON social.price_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_social_price_alerts_product_id ON social.price_alerts(product_id);
CREATE INDEX IF NOT EXISTS idx_social_price_alerts_active ON social.price_alerts(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_social_price_alerts_country ON social.price_alerts(country);

-- Table: social.chat_messages
CREATE TABLE IF NOT EXISTS social.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  country CHAR(2) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_chat_messages_user_id FOREIGN KEY (user_id) REFERENCES users.users(id) ON DELETE CASCADE
);

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_social_chat_messages_user_id ON social.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_social_chat_messages_created_at ON social.chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_social_chat_messages_country ON social.chat_messages(country);