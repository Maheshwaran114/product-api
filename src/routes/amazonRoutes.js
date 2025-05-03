const express = require('express');
const amazonController = require('../controllers/amazonController');
const router = express.Router();

/**
 * @route   GET /api/amazon/search
 * @desc    Search Amazon products by keyword
 * @query   {string} keyword - Search keyword
 * @query   {string} country - Country code (e.g. 'UK', 'US')
 * @access  Public
 */
router.get('/search', amazonController.searchProducts);

/**
 * @route   GET /api/amazon/countries
 * @desc    Get available Amazon country services
 * @access  Public
 */
router.get('/countries', amazonController.getAvailableCountries);

module.exports = router;