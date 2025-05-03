-- Database roles and permissions
-- Create application roles
CREATE ROLE api_read_role;
CREATE ROLE api_write_role;
CREATE ROLE api_admin_role;

-- Read-only permissions
GRANT USAGE ON SCHEMA public TO api_read_role;
GRANT USAGE ON SCHEMA users TO api_read_role;
GRANT USAGE ON SCHEMA agg TO api_read_role;
GRANT USAGE ON SCHEMA aff TO api_read_role;
GRANT USAGE ON SCHEMA social TO api_read_role;
GRANT USAGE ON SCHEMA fin TO api_read_role;
GRANT USAGE ON SCHEMA audit TO api_read_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO api_read_role;
GRANT SELECT ON ALL TABLES IN SCHEMA users TO api_read_role;
GRANT SELECT ON ALL TABLES IN SCHEMA agg TO api_read_role;
GRANT SELECT ON ALL TABLES IN SCHEMA aff TO api_read_role;
GRANT SELECT ON ALL TABLES IN SCHEMA social TO api_read_role;
GRANT SELECT ON ALL TABLES IN SCHEMA fin TO api_read_role;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO api_read_role;

-- Write permissions (includes read)
GRANT api_read_role TO api_write_role;

GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA users TO api_write_role;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA agg TO api_write_role;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA aff TO api_write_role;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA social TO api_write_role;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fin TO api_write_role;
GRANT INSERT ON ALL TABLES IN SCHEMA audit TO api_write_role;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA users TO api_write_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA agg TO api_write_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA aff TO api_write_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA social TO api_write_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA fin TO api_write_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA audit TO api_write_role;

-- Admin permissions (includes write and read)
GRANT api_write_role TO api_admin_role;

-- Admin can create/alter tables and schemas
GRANT ALL PRIVILEGES ON SCHEMA public TO api_admin_role;
GRANT ALL PRIVILEGES ON SCHEMA users TO api_admin_role;
GRANT ALL PRIVILEGES ON SCHEMA agg TO api_admin_role;
GRANT ALL PRIVILEGES ON SCHEMA aff TO api_admin_role;
GRANT ALL PRIVILEGES ON SCHEMA social TO api_admin_role;
GRANT ALL PRIVILEGES ON SCHEMA fin TO api_admin_role;
GRANT ALL PRIVILEGES ON SCHEMA audit TO api_admin_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA users TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA agg TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA aff TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA social TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fin TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO api_admin_role;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA users TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA agg TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA aff TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA social TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fin TO api_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO api_admin_role;

-- Create application users
CREATE USER api_user WITH PASSWORD 'secure_password_here';
CREATE USER api_admin WITH PASSWORD 'admin_secure_password_here';

-- Assign roles to users
GRANT api_write_role TO api_user;
GRANT api_admin_role TO api_admin;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA users GRANT SELECT ON TABLES TO api_read_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agg GRANT SELECT ON TABLES TO api_read_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA aff GRANT SELECT ON TABLES TO api_read_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA social GRANT SELECT ON TABLES TO api_read_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA fin GRANT SELECT ON TABLES TO api_read_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT ON TABLES TO api_read_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA users GRANT INSERT, UPDATE, DELETE ON TABLES TO api_write_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agg GRANT INSERT, UPDATE, DELETE ON TABLES TO api_write_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA aff GRANT INSERT, UPDATE, DELETE ON TABLES TO api_write_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA social GRANT INSERT, UPDATE, DELETE ON TABLES TO api_write_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA fin GRANT INSERT, UPDATE, DELETE ON TABLES TO api_write_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT INSERT ON TABLES TO api_write_role;

-- Comment on roles
COMMENT ON ROLE api_read_role IS 'Role for read-only access to the application';
COMMENT ON ROLE api_write_role IS 'Role for read-write access to the application';
COMMENT ON ROLE api_admin_role IS 'Role for administrative access to the application';