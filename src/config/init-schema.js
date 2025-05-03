/**
 * Database schema initialization module
 * Applies the multi-schema PostgreSQL structure with country tagging and GDPR compliance
 */
const fs = require('fs');
const path = require('path');
const { getPool } = require('./db');
const logger = require('../utils/logger');

/**
 * Initialize the database schema for a specific country
 * 
 * @param {string} countryCode - Two-letter country code (e.g., 'UK', 'US')
 * @returns {Promise<boolean>} - True if initialization was successful
 */
const initializeSchema = async (countryCode) => {
  const client = await getPool(countryCode).connect();
  
  try {
    logger.info(`Initializing database schema for ${countryCode}...`);
    
    // Read the schema.sql file
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schemaSQL = fs.readFileSync(schemaPath, 'utf8');
    
    // Set encryption key for the session (in production, use a secure method)
    await client.query("SET app.encryption_key = 'temp_key_for_development_only'");
    
    // Execute the schema creation SQL
    await client.query(schemaSQL);
    
    logger.info(`Database schema initialized successfully for ${countryCode}`);
    return true;
  } catch (error) {
    logger.error(`Database schema initialization failed for ${countryCode}: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Initialize the US-specific data migration to populate tables with Amazon US data
 * 
 * @param {string} countryCode - Should be 'US' for this migration
 * @returns {Promise<boolean>} - True if migration was successful
 */
const migrateUSData = async (countryCode = 'US') => {
  if (countryCode !== 'US') {
    logger.warn(`Attempted to run US data migration for non-US country code: ${countryCode}`);
    return false;
  }

  const client = await getPool(countryCode).connect();
  
  try {
    logger.info('Starting US data migration...');
    
    // Check if we have data to migrate (simple check for existing products)
    const { rows: amazonProducts } = await client.query(`
      SELECT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_name = 'products_amazon_us'
      ) as table_exists
    `);
    
    if (!amazonProducts[0].table_exists) {
      logger.info('No Amazon US data found to migrate. Skipping migration.');
      return true;
    }
    
    // Begin transaction for data migration
    await client.query('BEGIN');
    
    // Migrate Amazon US product data to the aggregate products table
    const { rowCount } = await client.query(`
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
      FROM 
        products_amazon_us
      ON CONFLICT (source, external_id) DO NOTHING
    `);
    
    logger.info(`Migrated ${rowCount} products from Amazon US to agg.products`);
    
    // Commit the transaction
    await client.query('COMMIT');
    
    logger.info('US data migration completed successfully');
    return true;
  } catch (error) {
    // Rollback in case of error
    await client.query('ROLLBACK');
    logger.error(`US data migration failed: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Initialize the database schema for all supported countries
 * 
 * @returns {Promise<object>} - Object with country codes as keys and success status as values
 */
const initializeDatabaseSchema = async () => {
  const { getSupportedCountries } = require('./db');
  const countries = getSupportedCountries();
  const results = {};
  
  for (const country of countries) {
    try {
      results[country] = await initializeSchema(country);
      
      // Special case for US to migrate Amazon US data
      if (country === 'US') {
        await migrateUSData();
      }
    } catch (error) {
      logger.error(`Failed to initialize schema for ${country}: ${error.message}`);
      results[country] = false;
    }
  }
  
  return results;
};

module.exports = {
  initializeSchema,
  migrateUSData,
  initializeDatabaseSchema
};