const express = require('express');
const bodyParser = require('body-parser');
const { errorHandler } = require('./utils/errorHandler');
const amazonRoutes = require('./routes/amazonRoutes');
const flipkartRoutes = require('./routes/flipkartRoutes');
const { connectDB } = require('./config/db');
const { initializeDatabase } = require('./config/init-db');
const logger = require('./utils/logger');
require('dotenv').config(); // Load environment variables directly

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to the database and initialize tables
const startServer = async () => {
  try {
    // Connect to the database
    await connectDB();
    logger.info('Database connection established');
    
    // Initialize database tables
    await initializeDatabase();
    
    // Start the server
    app.listen(PORT, () => {
      logger.info(`Server is running on port ${PORT}`);
    });
  } catch (err) {
    logger.error(`Failed to start server: ${err.message}`);
    process.exit(1);
  }
};

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.use('/api/amazon', amazonRoutes);
app.use('/api/flipkart', flipkartRoutes);

// Error handling middleware
app.use(errorHandler);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start the server
startServer();

module.exports = app; // Export for testing purposes