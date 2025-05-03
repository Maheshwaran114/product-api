/**
 * Global error handling middleware for Express
 */
const logger = require('./logger');

// Error handling middleware
const errorHandler = (err, req, res, next) => {
  // Log the error
  logger.error(`Error: ${err.message}`);
  logger.error(err.stack);

  // Set appropriate status code
  const statusCode = err.statusCode || 500;
  
  // Return error response
  res.status(statusCode).json({
    error: err.message || 'Internal Server Error',
    path: req.path,
    timestamp: new Date().toISOString()
  });
};

module.exports = { errorHandler };