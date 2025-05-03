-- 008_create_audit_triggers.sql
-- Add audit triggers to all tables for comprehensive change tracking
-- Created: May 2, 2025

-- Create audit triggers for the users schema
DROP TRIGGER IF EXISTS users_audit_trigger ON users.users;
CREATE TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users.users
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

-- Create audit triggers for the agg schema
DROP TRIGGER IF EXISTS products_audit_trigger ON agg.products;
CREATE TRIGGER products_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON agg.products
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

-- Create audit triggers for the aff schema
DROP TRIGGER IF EXISTS affiliate_products_audit_trigger ON aff.affiliate_products;
CREATE TRIGGER affiliate_products_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON aff.affiliate_products
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

-- Create audit triggers for the social schema
DROP TRIGGER IF EXISTS reviews_audit_trigger ON social.reviews;
CREATE TRIGGER reviews_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON social.reviews
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

DROP TRIGGER IF EXISTS questions_audit_trigger ON social.questions;
CREATE TRIGGER questions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON social.questions
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

DROP TRIGGER IF EXISTS price_alerts_audit_trigger ON social.price_alerts;
CREATE TRIGGER price_alerts_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON social.price_alerts
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

DROP TRIGGER IF EXISTS chat_messages_audit_trigger ON social.chat_messages;
CREATE TRIGGER chat_messages_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON social.chat_messages
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

-- Create audit triggers for the fin schema
DROP TRIGGER IF EXISTS transactions_audit_trigger ON fin.transactions;
CREATE TRIGGER transactions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON fin.transactions
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

DROP TRIGGER IF EXISTS payouts_audit_trigger ON fin.payouts;
CREATE TRIGGER payouts_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON fin.payouts
FOR EACH ROW EXECUTE FUNCTION audit.record_change();

COMMENT ON FUNCTION audit.record_change() IS 'Function to record all database changes for audit purposes, used by audit triggers';