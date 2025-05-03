/**
 * Migration Runner
 * 
 * Uses node-pg-migrate for database migrations
 * This module handles the execution of SQL migrations in the correct order
 */
const path = require('path');
const fs = require('fs');
const { getPool } = require('./db');
const logger = require('../utils/logger');

/**
 * Execute SQL file against the database
 * @param {Object} client - PostgreSQL client
 * @param {string} filePath - Path to SQL file
 * @returns {Promise<void>}
 */
async function executeSqlFile(client, filePath) {
  try {
    const sql = fs.readFileSync(filePath, 'utf8');
    await client.query(sql);
    logger.info(`Successfully executed migration: ${path.basename(filePath)}`);
    return true;
  } catch (error) {
    logger.error(`Error executing migration ${path.basename(filePath)}: ${error.message}`);
    throw error;
  }
}

/**
 * Read SQL files from directory in alphanumeric order
 * @param {string} dirPath - Path to directory containing SQL files
 * @returns {Array<string>} - Sorted array of file paths
 */
function getSqlFilesInOrder(dirPath) {
  if (!fs.existsSync(dirPath)) {
    logger.warn(`Migration directory does not exist: ${dirPath}`);
    return [];
  }

  return fs.readdirSync(dirPath)
    .filter(file => file.endsWith('.sql'))
    .sort()
    .map(file => path.join(dirPath, file));
}

/**
 * Execute all migrations in the specified directory
 * @param {Object} client - PostgreSQL client
 * @param {string} dirPath - Path to directory containing migrations
 * @param {Object} options - Migration options
 * @returns {Promise<Array<string>>} - List of executed migrations
 */
async function executeMigrationsInDirectory(client, dirPath, options = {}) {
  const { transactional = true } = options;

  const migrations = getSqlFilesInOrder(dirPath);
  if (migrations.length === 0) {
    logger.info(`No migrations found in ${dirPath}`);
    return [];
  }

  const executedMigrations = [];

  // Start transaction if transactional mode is enabled
  if (transactional) {
    await client.query('BEGIN');
  }

  try {
    for (const migration of migrations) {
      await executeSqlFile(client, migration);
      executedMigrations.push(path.basename(migration));
    }

    // Commit transaction if transactional mode is enabled
    if (transactional) {
      await client.query('COMMIT');
    }
    
    return executedMigrations;
  } catch (error) {
    // Rollback transaction on error if transactional mode is enabled
    if (transactional) {
      await client.query('ROLLBACK');
    }
    
    logger.error(`Failed to execute migrations: ${error.message}`);
    throw error;
  }
}

/**
 * Track executed migrations in the database
 * @param {Object} client - PostgreSQL client
 * @param {Array<string>} migrations - List of executed migrations
 * @returns {Promise<void>}
 */
async function trackMigrations(client, migrations) {
  if (migrations.length === 0) return;

  // Ensure migrations table exists
  await client.query(`
    CREATE TABLE IF NOT EXISTS migration_history (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      executed_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `);

  // Record executed migrations
  for (const migration of migrations) {
    await client.query(
      'INSERT INTO migration_history (name) VALUES ($1) ON CONFLICT DO NOTHING',
      [migration]
    );
  }
}

/**
 * Execute all migrations in the specified order
 * @param {string} countryCode - Country code for database connection
 * @returns {Promise<boolean>} - Success status
 */
async function runMigrations(countryCode = 'US') {
  const client = await getPool(countryCode).connect();
  let success = false;

  try {
    logger.info(`Running migrations for ${countryCode} database...`);
    
    // Base migrations directory
    const migrationsDir = path.join(__dirname, 'migrations');
    
    // 1. Execute legacy migrations first
    const legacyMigrations = await executeMigrationsInDirectory(
      client, 
      path.join(migrationsDir, 'legacy')
    );
    
    // 2. Execute schema migrations
    const schemaMigrations = await executeMigrationsInDirectory(
      client, 
      path.join(migrationsDir, 'schema')
    );
    
    // Track all schema migrations
    await trackMigrations(client, [...legacyMigrations, ...schemaMigrations]);
    
    // 3. Execute seed migrations (only in development)
    if (process.env.NODE_ENV !== 'production' && process.env.LOAD_SAMPLE_DATA === 'true') {
      const seedMigrations = await executeMigrationsInDirectory(
        client, 
        path.join(migrationsDir, 'seed'),
        { transactional: true }
      );
      logger.info(`Loaded ${seedMigrations.length} seed data files`);
    }
    
    logger.info(`Successfully completed migrations for ${countryCode}`);
    success = true;
  } catch (error) {
    logger.error(`Migration failed for ${countryCode}: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
  
  return success;
}

/**
 * Run migrations for all supported countries
 * @returns {Promise<Object>} - Object with country codes as keys and success status as values
 */
async function runAllMigrations() {
  // Define supported countries directly since there appears to be an issue with module loading
  const countries = ['UK', 'US', 'DE', 'FR', 'CA'];
  const results = {};
  
  for (const country of countries) {
    try {
      results[country] = await runMigrations(country);
    } catch (error) {
      results[country] = false;
      logger.error(`Failed to run migrations for ${country}`);
      // Continue with other countries even if one fails
    }
  }
  
  return results;
}

module.exports = { 
  runMigrations,
  runAllMigrations
};