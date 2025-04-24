const axios = require('axios');
const crypto = require('crypto');
const { AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AMAZON_TAG } = require('../config/env');
const { pool } = require('../config/db');

class AmazonService {
  constructor() {
    this.host = 'webservices.amazon.in';
    this.region = 'eu-west-1';
    this.uri = '/paapi5/searchitems';
    this.accessKey = AWS_ACCESS_KEY_ID;
    this.secretKey = AWS_SECRET_ACCESS_KEY;
    this.partnerTag = AMAZON_TAG;
    this.service = 'ProductAdvertisingAPI';
  }

  // Generate the required headers for Amazon PA API 5.0
  generateHeaders(payload) {
    const date = new Date();
    const amzDate = date.toISOString().replace(/[:-]|\.\d{3}/g, '');
    const datestamp = amzDate.slice(0, 8);
    
    // Create canonical request
    const canonicalUri = this.uri;
    const canonicalQueryString = '';
    const canonicalHeaders = 
      `content-encoding:amz-1.0\n` +
      `content-type:application/json; charset=utf-8\n` +
      `host:${this.host}\n` +
      `x-amz-date:${amzDate}\n` +
      `x-amz-target:com.amazon.paapi5.v1.ProductAdvertisingAPIv1.SearchItems\n`;
    const signedHeaders = 'content-encoding;content-type;host;x-amz-date;x-amz-target';
    
    const payloadHash = crypto
      .createHash('sha256')
      .update(JSON.stringify(payload))
      .digest('hex');
    
    const canonicalRequest = 
      `POST\n${canonicalUri}\n${canonicalQueryString}\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;
    
    // Create string to sign
    const algorithm = 'AWS4-HMAC-SHA256';
    const credentialScope = `${datestamp}/${this.region}/${this.service}/aws4_request`;
    const stringToSign = 
      `${algorithm}\n${amzDate}\n${credentialScope}\n${
        crypto.createHash('sha256').update(canonicalRequest).digest('hex')
      }`;
    
    // Calculate signature
    const kDate = crypto
      .createHmac('sha256', `AWS4${this.secretKey}`)
      .update(datestamp)
      .digest();
    const kRegion = crypto
      .createHmac('sha256', kDate)
      .update(this.region)
      .digest();
    const kService = crypto
      .createHmac('sha256', kRegion)
      .update(this.service)
      .digest();
    const kSigning = crypto
      .createHmac('sha256', kService)
      .update('aws4_request')
      .digest();
    const signature = crypto
      .createHmac('sha256', kSigning)
      .update(stringToSign)
      .digest('hex');
    
    // Create authorization header
    const authorizationHeader = 
      `${algorithm} ` +
      `Credential=${this.accessKey}/${credentialScope}, ` +
      `SignedHeaders=${signedHeaders}, ` +
      `Signature=${signature}`;
    
    return {
      'host': this.host,
      'x-amz-date': amzDate,
      'x-amz-target': 'com.amazon.paapi5.v1.ProductAdvertisingAPIv1.SearchItems',
      'content-encoding': 'amz-1.0',
      'content-type': 'application/json; charset=utf-8',
      'authorization': authorizationHeader,
    };
  }

  // Fetch products from Amazon PA API
  async fetchProducts(keyword) {
    try {
      const payload = {
        "PartnerTag": this.partnerTag,
        "PartnerType": "Associates",
        "Keywords": keyword,
        "SearchIndex": "All",
        "ItemCount": 10,
        "Resources": [
          "ItemInfo.Title",
          "Offers.Listings.Price",
          "Images.Primary.Medium"
        ]
      };

      const response = await axios({
        url: `https://${this.host}${this.uri}`,
        method: 'POST',
        headers: this.generateHeaders(payload),
        data: payload
      });

      if (!response.data.SearchResult || !response.data.SearchResult.Items) {
        return [];
      }

      // Map the response to a standardized format
      const products = response.data.SearchResult.Items.map(item => {
        const price = item.Offers && item.Offers.Listings && item.Offers.Listings[0] ? 
          item.Offers.Listings[0].Price.Amount : 0;
        const currency = item.Offers && item.Offers.Listings && item.Offers.Listings[0] ? 
          item.Offers.Listings[0].Price.Currency : 'INR';
        const imageUrl = item.Images && item.Images.Primary ? item.Images.Primary.Medium.URL : '';

        return {
          source: 'Amazon',
          external_id: item.ASIN,
          title: item.ItemInfo.Title.DisplayValue,
          price,
          currency,
          image_url: imageUrl
        };
      });

      // Store products in the database
      await this.storeProducts(products);

      return products;
    } catch (error) {
      console.error('Error fetching products from Amazon:', error.message);
      throw new Error(`Failed to fetch products from Amazon: ${error.message}`);
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
      console.error('Database error storing Amazon products:', error);
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new AmazonService();