const { Pool } = require('pg');

// Single database pool
let pool = null;

// Default country code
const DEFAULT_COUNTRY = 'UK';

// Get database connection pool (single pool for all countries)
const getPool = () => {
  if (!pool) {
    // Create a new pool for the single database if it doesn't exist
    pool = new Pool({
      host: process.env.PGHOST || 'db',
      port: process.env.PGPORT || 5432,
      user: process.env.PGUSER || 'postgres',
      password: process.env.PGPASSWORD || 'postgres',
      database: process.env.PGDATABASE || 'productdb',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
    
    // Add error handling for the pool
    pool.on('error', (err, client) => {
      console.error('Unexpected error on idle client:', err);
    });
  }
  
  return pool;
};

// Execute a query with country filtering
const executeQuery = async (text, params, countryCode = DEFAULT_COUNTRY) => {
  const client = await getPool().connect();
  try {
    // Set search_path to include all schemas
    await client.query('SET search_path TO users, agg, aff, social, fin, audit, public');
    
    // Set session variable for country code for potential use in queries/functions
    await client.query('SET app.current_country = $1', [countryCode.toUpperCase()]);
    
    return await client.query(text, params);
  } finally {
    client.release();
  }
};

// Function to test database connection
const connectDB = async () => {
  try {
    const client = await getPool().connect();
    console.log('PostgreSQL connected successfully');
    
    // Test country filtering by querying the database
    const supportedCountries = ['UK', 'US', 'DE', 'FR', 'CA'];
    for (const country of supportedCountries) {
      await client.query('SET app.current_country = $1', [country]);
      console.log(`Successfully set country context for ${country}`);
    }
    
    client.release();
    return true;
  } catch (error) {
    console.error('Database connection error:', error.message);
    throw error;
  }
};

// For testing: reset connection pool
const resetConnection = () => {
  if (pool) {
    pool.end();
    pool = null;
  }
};

// Get all supported country codes
const getSupportedCountries = () => {
  return ['UK', 'US', 'DE', 'FR', 'CA'];
};

module.exports = { 
  getPool,
  executeQuery,
  connectDB,
  resetConnection,
  getSupportedCountries,
  DEFAULT_COUNTRY
};