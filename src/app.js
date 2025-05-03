const express = require('express');
const bodyParser = require('body-parser');
const { errorHandler } = require('./utils/errorHandler');
const amazonRoutes = require('./routes/amazonRoutes');
const db = require('./config/db'); // Import the entire db module
const { initializeDatabase } = require('./config/init-db');
const { runAllMigrations } = require('./config/migration-runner');
const logger = require('./utils/logger');
require('dotenv').config(); // Load environment variables directly

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.use('/api/amazon', amazonRoutes);

// Error handling middleware
app.use(errorHandler);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Database status endpoint with schema information
app.get('/db-status', async (req, res) => {
  try {
    const dbStatus = {
      legacy_tables: {},
      schemas: ['users', 'agg', 'aff', 'social', 'fin', 'audit'],
      schema_status: {},
      connected: true
    };
    
    res.status(200).json(dbStatus);
  } catch (error) {
    res.status(500).json({ 
      status: 'error',
      message: `Database status check failed: ${error.message}` 
    });
  }
});

// Connect to the database and initialize tables - exported as a function for testing
const startServer = async (customDBConnection) => {
  try {
    // Connect to the database
    if (customDBConnection) {
      await customDBConnection();
    } else {
      await db.connectDB();
    }
    logger.info('Database connection established');
    
    // For backward compatibility: initialize legacy tables
    if (process.env.USE_LEGACY_TABLES === 'true') {
      await initializeDatabase(null, false);
      logger.info('Legacy database tables initialized');
    }
    
    // Use migration runner for schema setup if enabled
    if (process.env.USE_MIGRATIONS === 'true') {
      logger.info('Running database migrations...');
      const migrationResults = await runAllMigrations();
      
      // Log migration results
      Object.entries(migrationResults).forEach(([country, success]) => {
        if (success) {
          logger.info(`Migrations for ${country} completed successfully`);
        } else {
          logger.warn(`Migrations for ${country} failed or were incomplete`);
        }
      });
    }
    
    // Start the server
    const server = app.listen(PORT, () => {
      logger.info(`Server is running on port ${PORT}`);
    });
    
    return server;
  } catch (err) {
    logger.error(`Failed to start server: ${err.message}`);
    throw err; // Throw error instead of exiting process for better test handling
  }
};

// Only start server if this file is run directly (not imported in tests)
if (require.main === module) {
  startServer().catch(err => {
    process.exit(1);
  });
}

module.exports = { app, startServer };