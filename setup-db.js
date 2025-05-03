/**
 * Database Setup Script
 * 
 * This script sets up a single database with country tagging and GDPR compliance.
 * It applies migrations to create schemas and tables with country partitioning.
 */
require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const logger = require('./src/utils/logger');

// Hard-coded credentials to match pgAdmin settings
const PG_USER = 'postgres';
const PG_PASSWORD = 'admin';
const PG_HOST = 'localhost';
const PG_PORT = 5432;
const PG_DATABASE = 'productdb'; // Single database for all countries

/**
 * Execute SQL file against the database
 * @param {Object} client - PostgreSQL client
 * @param {string} filePath - Path to SQL file
 * @returns {Promise<boolean>}
 */
async function executeSqlFile(client, filePath) {
  try {
    const sql = fs.readFileSync(filePath, 'utf8');
    await client.query(sql);
    console.log(`Successfully executed migration: ${path.basename(filePath)}`);
    return true;
  } catch (error) {
    console.error(`Error executing migration ${path.basename(filePath)}: ${error.message}`);
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
    console.warn(`Migration directory does not exist: ${dirPath}`);
    return [];
  }

  return fs.readdirSync(dirPath)
    .filter(file => file.endsWith('.sql'))
    .sort()
    .map(file => path.join(dirPath, file));
}

/**
 * Apply migrations to the single database
 * @returns {Promise<boolean>}
 */
async function applyMigrations() {
  // Connect to the single database using hard-coded credentials
  const pool = new Pool({
    host: PG_HOST,
    port: PG_PORT,
    user: PG_USER,
    password: PG_PASSWORD,
    database: PG_DATABASE
  });
  
  const client = await pool.connect();
  
  try {
    console.log(`Connected to ${PG_DATABASE}, applying migrations...`);
    
    // Base migrations directory
    const migrationsDir = path.join(__dirname, 'src/config/migrations');
    
    // 1. Apply legacy migrations first
    console.log('Applying legacy migrations...');
    const legacyFiles = getSqlFilesInOrder(path.join(migrationsDir, 'legacy'));
    for (const file of legacyFiles) {
      await executeSqlFile(client, file);
    }
    
    // 2. Apply schema migrations
    console.log('Applying schema migrations...');
    const schemaFiles = getSqlFilesInOrder(path.join(migrationsDir, 'schema'));
    for (const file of schemaFiles) {
      await executeSqlFile(client, file);
    }
    
    // 3. Apply seed migrations (only in development)
    if (process.env.NODE_ENV !== 'production' && process.env.LOAD_SAMPLE_DATA === 'true') {
      console.log('Applying seed data...');
      const seedFiles = getSqlFilesInOrder(path.join(migrationsDir, 'seed'));
      for (const file of seedFiles) {
        await executeSqlFile(client, file);
      }
    }
    
    console.log(`Successfully completed migrations for ${PG_DATABASE}`);
    return true;
  } catch (error) {
    console.error(`Failed to apply migrations to ${PG_DATABASE}: ${error.message}`);
    return false;
  } finally {
    client.release();
    await pool.end();
  }
}

/**
 * Setup the database
 */
async function setupDatabase() {
  try {
    console.log(`Setting up database ${PG_DATABASE}...`);
    const result = await applyMigrations();
    
    console.log('Database setup result:');
    console.log(JSON.stringify({ success: result }, null, 2));
  } catch (error) {
    console.error(`Error setting up database:`, error.message);
    console.log(JSON.stringify({ success: false }, null, 2));
  }
}

// Run the setup
setupDatabase();