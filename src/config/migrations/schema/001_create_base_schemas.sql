-- 001_create_base_schemas.sql
-- Base schema creation for multi-schema PostgreSQL architecture
-- Created: May 1, 2025

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create the six schemas for our architecture
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS agg;
CREATE SCHEMA IF NOT EXISTS aff;
CREATE SCHEMA IF NOT EXISTS social;
CREATE SCHEMA IF NOT EXISTS fin;
CREATE SCHEMA IF NOT EXISTS audit;