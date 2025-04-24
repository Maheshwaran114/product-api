const { pool } = require('./db');
const logger = require('../utils/logger');

/**
 * Initializes the database by creating necessary tables if they don't exist
 */
const initializeDatabase = async () => {
  const client = await pool.connect();
  
  try {
    logger.info('Initializing database tables...');
    
    // Create products table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        source VARCHAR(50) NOT NULL,
        external_id VARCHAR(100) NOT NULL,
        title TEXT,
        price NUMERIC,
        currency VARCHAR(3),
        image_url TEXT,
        retrieved_at TIMESTAMP DEFAULT now(),
        UNIQUE(source, external_id)
      );
    `);
    
    logger.info('Database initialization completed successfully');
  } catch (error) {
    logger.error(`Database initialization failed: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

module.exports = { initializeDatabase };