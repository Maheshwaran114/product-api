const axios = require('axios');
const { FK_ID, FK_TOKEN } = require('../config/env');
const { pool } = require('../config/db');

class FlipkartService {
  constructor() {
    this.apiUrl = 'https://affiliate-api.flipkart.net/affiliate/1.0/search.json';
    this.fkId = FK_ID;
    this.fkToken = FK_TOKEN;
  }

  // Fetch products from Flipkart API
  async searchProducts(keyword) {
    try {
      const response = await axios.get(this.apiUrl, {
        headers: {
          'Fk-Affiliate-Id': this.fkId,
          'Fk-Affiliate-Token': this.fkToken,
        },
        params: {
          query: keyword,
          resultCount: 10,
        },
      });

      if (!response.data || !response.data.products) {
        return [];
      }

      // Map the response to a standardized format
      const products = response.data.products.map(product => {
        return {
          source: 'Flipkart',
          external_id: product.productBaseInfoV1.productId,
          title: product.productBaseInfoV1.title,
          price: parseFloat(product.productBaseInfoV1.maximumRetailPrice.amount),
          currency: product.productBaseInfoV1.maximumRetailPrice.currency,
          image_url: product.productBaseInfoV1.imageUrls.x200
        };
      });

      // Store products in the database
      await this.storeProducts(products);

      return products;
    } catch (error) {
      console.error('Error fetching products from Flipkart:', error.message);
      throw new Error(`Failed to fetch products from Flipkart: ${error.message}`);
    }
  }

  // Store products in the database
  async storeProducts(products) {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      for (const product of products) {
        await client.query(
          `INSERT INTO products 
           (source, external_id, title, price, currency, image_url)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (source, external_id) 
           DO UPDATE SET 
             title = EXCLUDED.title,
             price = EXCLUDED.price,
             currency = EXCLUDED.currency,
             image_url = EXCLUDED.image_url,
             retrieved_at = NOW()`,
          [
            product.source,
            product.external_id,
            product.title,
            product.price,
            product.currency,
            product.image_url
          ]
        );
      }
      
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Database error storing Flipkart products:', error);
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new FlipkartService();