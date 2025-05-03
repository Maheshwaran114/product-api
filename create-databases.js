/**
 * Create PostgreSQL Databases for Each Country
 * 
 * This script creates the necessary databases for each supported country.
 * Run this before applying migrations.
 */
require('dotenv').config();
const { Pool } = require('pg');
const { getSupportedCountries } = require('./src/config/db');

async function createDatabases() {
  // Connect to default PostgreSQL database for creating other databases
  const pool = new Pool({
    host: process.env.PGHOST || 'localhost',
    port: process.env.PGPORT || 5432,
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || 'postgres',
    database: 'postgres' // Connect to default database
  });

  try {
    console.log('Connected to PostgreSQL server');
    const countries = getSupportedCountries();
    
    for (const country of countries) {
      const dbName = `productdb_${country.toLowerCase()}`;
      
      try {
        console.log(`Creating database ${dbName} if it doesn't exist...`);
        
        // Check if database exists
        const { rows } = await pool.query(
          "SELECT 1 FROM pg_database WHERE datname = $1",
          [dbName]
        );
        
        if (rows.length === 0) {
          // Database doesn't exist, create it
          await pool.query(`CREATE DATABASE ${dbName}`);
          console.log(`Database ${dbName} created successfully`);
        } else {
          console.log(`Database ${dbName} already exists, skipping creation`);
        }
      } catch (err) {
        console.error(`Error creating database ${dbName}:`, err.message);
      }
    }
    
    console.log('Database creation process completed');
  } catch (err) {
    console.error('Failed to connect to PostgreSQL server:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

createDatabases();