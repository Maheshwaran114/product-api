const { Pool } = require('pg');
const { PGHOST, PGUSER, PGPASSWORD, PGDATABASE, PGPORT } = require('./env');

const pool = new Pool({
  host: PGHOST,
  user: PGUSER,
  password: PGPASSWORD,
  database: PGDATABASE,
  port: PGPORT,
});

const connectDB = async () => {
  try {
    await pool.connect();
    console.log('PostgreSQL connected successfully');
  } catch (error) {
    console.error('Database connection error:', error.message);
    process.exit(1);
  }
};

module.exports = {
  pool,
  connectDB,
};