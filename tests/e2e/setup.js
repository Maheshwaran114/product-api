// Global setup for E2E tests
const { GenericContainer, Wait } = require('testcontainers');
const { Pool } = require('pg');

// Global variables to store test container resources
let postgresContainer;
let testPool;

// Function to create a custom DB connection for tests
const createTestDbConnection = () => {
  return async () => {
    try {
      // Create a client using the test pool
      const client = await testPool.connect();
      console.log('Test database connected successfully');
      client.release();
      return true;
    } catch (error) {
      console.error('Test database connection error:', error.message);
      throw error;
    }
  };
};

beforeAll(async () => {
  console.log('Starting test containers for E2E tests...');
  
  try {
    // Start Postgres container with wait strategy
    postgresContainer = await new GenericContainer('postgres:14')
      .withExposedPorts(5432)
      .withEnvironment({
        POSTGRES_USER: 'postgres',
        POSTGRES_PASSWORD: 'postgres',
        POSTGRES_DB: 'productdb'
      })
      .withWaitStrategy(Wait.forLogMessage('database system is ready to accept connections'))
      .start();
    
    // Get the mapped port for PostgreSQL
    const postgresPort = postgresContainer.getMappedPort(5432);
    console.log(`PostgreSQL container started on port ${postgresPort}`);
    
    // Create a connection pool specifically for tests
    testPool = new Pool({
      host: 'localhost',  // Always use localhost in tests since container is exposed on host
      port: postgresPort, // Use the dynamically assigned port
      user: 'postgres',
      password: 'postgres',
      database: 'productdb',
      max: 10,
      connectionTimeoutMillis: 5000
    });
    
    // Override environment variables for the application
    process.env.PGHOST = 'localhost';
    process.env.PGPORT = postgresPort;
    process.env.PGUSER = 'postgres';
    process.env.PGPASSWORD = 'postgres';
    process.env.PGDATABASE = 'productdb';
    
    // Initialize the database schema
    const client = await testPool.connect();
    await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        source VARCHAR(255) NOT NULL,
        external_id VARCHAR(255) NOT NULL,
        title VARCHAR(512) NOT NULL,
        brand VARCHAR(255),
        price NUMERIC,
        currency VARCHAR(10),
        rating NUMERIC,
        reviews_count INTEGER,
        image_url TEXT,
        product_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(source, external_id)
      )
    `);
    client.release();
    
    console.log('Test containers and database setup completed successfully');
  } catch (error) {
    console.error('Error setting up test containers:', error);
    throw error;
  }
}, 30000); // 30 second timeout for container startup

afterAll(async () => {
  console.log('Cleaning up test environment...');
  
  try {
    // Close the test database pool
    if (testPool) {
      await testPool.end();
    }
    
    // Stop the containers
    if (postgresContainer) {
      await postgresContainer.stop();
      console.log('PostgreSQL container stopped');
    }
  } catch (error) {
    console.error('Error cleaning up test environment:', error);
  }
});

// Export the function to create a test DB connection
module.exports = {
  createTestDbConnection,
  getTestPool: () => testPool
};