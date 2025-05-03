/**
 * Amazon Service Factory
 * 
 * This module manages country-specific Amazon service implementations
 * and provides a consistent interface for the rest of the application.
 */

const amazonService_UK = require('./amazonService_UK');
// Future imports will be added here as they are implemented
// const amazonService_US = require('./amazonService_US');
// const amazonService_CA = require('./amazonService_CA');
// etc.

// A map of country codes to their respective service implementations
const services = {
  UK: amazonService_UK,
  // US: amazonService_US,
  // CA: amazonService_CA,
  // Add more country services as they are implemented
};

// Default country code if none is specified
const DEFAULT_COUNTRY = 'UK';

/**
 * Get the Amazon service for a specific country
 * @param {string} countryCode - The country code (UK, US, CA, etc.)
 * @returns {Object} The country-specific Amazon service
 */
function getServiceForCountry(countryCode = DEFAULT_COUNTRY) {
  const service = services[countryCode.toUpperCase()];
  
  if (!service) {
    throw new Error(`Amazon service for country "${countryCode}" not implemented`);
  }
  
  return service;
}

/**
 * Get a list of all supported country codes
 * @returns {Array<string>} List of country codes
 */
function getSupportedCountries() {
  return Object.keys(services);
}

/**
 * Generic function to fetch products that delegates to the appropriate country service
 * @param {string} keyword - Search keyword
 * @param {string} countryCode - Optional country code (defaults to UK)
 * @returns {Promise<Array>} Products from the specified country's Amazon service
 */
async function fetchProducts(keyword, countryCode = DEFAULT_COUNTRY) {
  const service = getServiceForCountry(countryCode);
  return service.fetchProducts(keyword);
}

/**
 * Store products in the database for a specific country
 * @param {Array<Object>} products - Array of product objects to store
 * @param {string} countryCode - Optional country code (defaults to UK)
 * @returns {Promise<void>}
 */
async function storeProducts(products, countryCode = DEFAULT_COUNTRY) {
  const service = getServiceForCountry(countryCode);
  return service.storeProducts(products);
}

module.exports = {
  fetchProducts,
  storeProducts,
  getServiceForCountry,
  getSupportedCountries,
  // Export the UK service as the default for backward compatibility
  ...amazonService_UK
};