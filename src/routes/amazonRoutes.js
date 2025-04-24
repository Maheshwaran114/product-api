const express = require('express');
const AmazonController = require('../controllers/amazonController');

const router = express.Router();
const amazonController = new AmazonController();

router.get('/search', amazonController.search.bind(amazonController));

module.exports = router;