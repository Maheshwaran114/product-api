const express = require('express');
const FlipkartController = require('../controllers/flipkartController');

const router = express.Router();
const flipkartController = new FlipkartController();

router.get('/search', flipkartController.search.bind(flipkartController));

module.exports = router;