const { getPool } = require('./db');
const { getSupportedCountries } = require('../services/amazonService');
const logger = require('../utils/logger');
const { initializeSchema } = require('./init-schema');

/**
 * Creates a products table for a specific affiliate provider in a country database
 * 
 * @param {Object} client - Database client
 * @param {String} countryCode - Two-letter country code (e.g., 'UK')
 * @param {String} affiliateCode - Affiliate provider code (e.g., 'amazon')
 * @returns {Promise<void>}
 */
const createAffiliateTable = async (client, countryCode, affiliateCode) => {
  const tableName = `products_${affiliateCode.toLowerCase()}_${countryCode.toLowerCase()}`;
  
  await client.query(`
    CREATE TABLE IF NOT EXISTS ${tableName} (
      id SERIAL PRIMARY KEY,
      external_id VARCHAR(100) NOT NULL,
      title TEXT,
      description TEXT,
      brand VARCHAR(255),
      manufacturer VARCHAR(255),
      category VARCHAR(255),
      sub_category VARCHAR(255),
      
      /* Price information */
      price NUMERIC,
      list_price NUMERIC,
      price_saved NUMERIC,
      discount_percentage SMALLINT,
      currency VARCHAR(3),
      
      /* Product details */
      product_url TEXT,
      features TEXT[],
      specifications JSONB,
      
      /* Product availability */
      availability VARCHAR(100),
      is_prime BOOLEAN,
      fulfillment_type VARCHAR(100),
      
      /* Media */
      image_url TEXT,
      additional_image_urls TEXT[],
      
      /* Ratings & Reviews */
      rating NUMERIC(3,1),
      total_reviews INTEGER,
      
      /* Timestamps */
      retrieved_at TIMESTAMP DEFAULT now(),
      updated_at TIMESTAMP DEFAULT now(),
      country CHAR(2) NOT NULL DEFAULT '${countryCode}',
      
      UNIQUE(external_id)
    );
    
    /* Create indexes for faster searches */
    CREATE INDEX IF NOT EXISTS idx_${tableName}_brand ON ${tableName}(brand);
    CREATE INDEX IF NOT EXISTS idx_${tableName}_category ON ${tableName}(category);
    CREATE INDEX IF NOT EXISTS idx_${tableName}_price ON ${tableName}(price);
    CREATE INDEX IF NOT EXISTS idx_${tableName}_rating ON ${tableName}(rating);
    CREATE INDEX IF NOT EXISTS idx_${tableName}_country ON ${tableName}(country);
  `);
  
  logger.info(`Created or verified table: ${tableName}`);
};

/**
 * Initializes a country database by creating necessary affiliate tables
 * 
 * @param {String} countryCode - Two-letter country code (e.g., 'UK')
 * @returns {Promise<Boolean>} - True if initialization was successful
 */
const initializeCountryDatabase = async (countryCode) => {
  const client = await getPool(countryCode).connect();
  
  try {
    logger.info(`Initializing database tables for ${countryCode}...`);
    
    // List of affiliate providers for each country
    const affiliatesByCountry = {
      'UK': ['amazon', 'ebay', 'argos', 'john_lewis', 'currys', 'very'],
      'US': ['amazon', 'walmart', 'bestbuy', 'target', 'ebay'],
      'DE': ['amazon', 'otto', 'zalando', 'mediamarkt', 'saturn'],
      'FR': ['amazon', 'fnac', 'cdiscount', 'carrefour', 'leroy_merlin'],
      'CA': ['amazon', 'walmart', 'bestbuy', 'canadian_tire', 'the_bay']
    };
    
    // Get affiliates for this country or use a default list
    const affiliates = affiliatesByCountry[countryCode] || ['amazon'];
    
    // Create a table for each affiliate
    for (const affiliate of affiliates) {
      await createAffiliateTable(client, countryCode, affiliate);
    }
    
    logger.info(`Database initialization completed successfully for ${countryCode}`);
    return true;
  } catch (error) {
    logger.error(`Database initialization failed for ${countryCode}: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Initializes all country databases with both legacy tables and new multi-schema architecture
 * @param {String} countryCode - Optional specific country code to initialize
 * @param {Boolean} useNewSchema - Whether to use the new multi-schema architecture
 */
const initializeDatabase = async (countryCode = null, useNewSchema = true) => {
  try {
    // First initialize the legacy tables for backward compatibility
    if (countryCode) {
      // Initialize for specific country
      const legacyResult = await initializeCountryDatabase(countryCode);
      
      // If new schema is requested, also initialize the multi-schema architecture
      if (useNewSchema) {
        const schemaResult = await initializeSchema(countryCode);
        return { legacy: legacyResult, schema: schemaResult };
      }
      
      return { legacy: legacyResult };
    } else {
      // Initialize for all supported countries
      const countries = getSupportedCountries();
      const results = {};
      
      for (const country of countries) {
        try {
          // Initialize legacy tables
          results[country] = { 
            legacy: await initializeCountryDatabase(country) 
          };
          
          // Initialize new schema if requested
          if (useNewSchema) {
            results[country].schema = await initializeSchema(country);
          }
        } catch (error) {
          logger.error(`Failed to initialize database for ${country}`);
          results[country] = { legacy: false, schema: false };
        }
      }
      
      return results;
    }
  } catch (error) {
    logger.error(`Database initialization failed: ${error.message}`);
    throw error;
  }
};

module.exports = { 
  initializeDatabase,
  initializeCountryDatabase
};