const logger = require('./logger');

/**
 * Global error handling middleware for Express
 */
const errorHandler = (err, req, res, next) => {
  // Log the error
  logger.error(`${err.name}: ${err.message}`);
  logger.error(err.stack);

  // Set default error status and message
  const status = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  // Send error response
  res.status(status).json({
    error: message,
    status: status
  });
};

module.exports = { errorHandler };