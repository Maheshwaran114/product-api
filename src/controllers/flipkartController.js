const flipkartService = require('../services/flipkartService');
const { pool } = require('../config/db');
const logger = require('../utils/logger');

class FlipkartController {
    async search(req, res) {
        const keyword = req.query.q;

        if (!keyword) {
            return res.status(400).json({ error: 'Search keyword is required' });
        }

        try {
            // Call the Flipkart service to fetch products
            const products = await flipkartService.searchProducts(keyword);
            
            // Return the products (already limited to 10 in the service)
            res.json(products);
        } catch (error) {
            // Log the error and send a response
            logger.error(`Flipkart API error: ${error.message}`);
            res.status(500).json({ error: 'An error occurred while fetching products from Flipkart.' });
        }
    }
}

module.exports = FlipkartController;