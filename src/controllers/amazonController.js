const amazonService = require('../services/amazonService');
const { pool } = require('../config/db');

class AmazonController {
    async search(req, res) {
        const keyword = req.query.q;

        if (!keyword) {
            return res.status(400).json({ error: 'Search keyword is required' });
        }

        try {
            // Call the Amazon service to fetch products
            const products = await amazonService.fetchProducts(keyword);

            // Return the top 10 products
            res.json(products.slice(0, 10));
        } catch (error) {
            console.error('Amazon API error:', error.message);
            res.status(500).json({ error: 'An error occurred while fetching products from Amazon.' });
        }
    }
}

module.exports = AmazonController;