const axios = require('axios');
const crypto = require('crypto');
const { AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AMAZON_TAG } = require('../config/env');
const { getPool } = require('../config/db');

class AmazonService_UK {
  constructor() {
    this.countryCode = 'UK';
    this.affiliateCode = 'amazon';
    this.host = 'webservices.amazon.co.uk';
    this.region = 'eu-west-1';
    this.uri = '/paapi5/searchitems';
    this.accessKey = AWS_ACCESS_KEY_ID;
    this.secretKey = AWS_SECRET_ACCESS_KEY;
    this.partnerTag = AMAZON_TAG; 
    this.service = 'ProductAdvertisingAPI';
    this.tableName = `products_${this.affiliateCode}_${this.countryCode.toLowerCase()}`;
    this.marketplace = 'www.amazon.co.uk';
    this.sourceName = 'Amazon UK';
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

  // Fetch products from Amazon UK PA API
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
          "ItemInfo.Features",
          "ItemInfo.ProductInfo",
          "ItemInfo.ByLineInfo",
          "ItemInfo.ManufactureInfo",
          "ItemInfo.ContentInfo",
          "ItemInfo.Classifications",
          "ItemInfo.ExternalIds",
          "ItemInfo.TechnicalInfo",
          "ItemInfo.ContentRating",
          "Images.Primary.Small",
          "Images.Primary.Medium",
          "Images.Primary.Large",
          "Images.Variants.Small",
          "Images.Variants.Medium",
          "Images.Variants.Large",
          "Offers.Listings.Price",
          "Offers.Listings.SavingBasis",
          "Offers.Listings.Availability",
          "Offers.Listings.Condition",
          "Offers.Listings.DeliveryInfo.IsPrimeEligible",
          "Offers.Summaries.OfferCount",
          "BrowseNodeInfo.BrowseNodes",
          "CustomerReviews.Count",
          "CustomerReviews.StarRating",
          "ParentASIN"
        ],
        "Marketplace": this.marketplace
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
        // Default values
        const defaultProduct = {
          external_id: item.ASIN,
          title: '',
          description: '',
          brand: '',
          manufacturer: '',
          category: '',
          sub_category: '',
          price: 0,
          list_price: 0,
          price_saved: 0,
          discount_percentage: 0,
          currency: 'GBP',
          product_url: `https://${this.marketplace}/dp/${item.ASIN}?tag=${this.partnerTag}`,
          features: [],
          specifications: {},
          availability: '',
          is_prime: false,
          fulfillment_type: '',
          image_url: '',
          additional_image_urls: [],
          rating: 0,
          total_reviews: 0
        };

        // Extract title
        if (item.ItemInfo && item.ItemInfo.Title) {
          defaultProduct.title = item.ItemInfo.Title.DisplayValue;
        }

        // Extract price information
        if (item.Offers && item.Offers.Listings && item.Offers.Listings[0]) {
          const listing = item.Offers.Listings[0];
          if (listing.Price) {
            defaultProduct.price = listing.Price.Amount;
            defaultProduct.currency = listing.Price.Currency;
          }
          
          if (listing.SavingBasis) {
            defaultProduct.list_price = listing.SavingBasis.Amount;
            if (defaultProduct.list_price > 0 && defaultProduct.price > 0) {
              defaultProduct.price_saved = defaultProduct.list_price - defaultProduct.price;
              defaultProduct.discount_percentage = Math.round((defaultProduct.price_saved / defaultProduct.list_price) * 100);
            }
          }
          
          if (listing.Availability) {
            defaultProduct.availability = listing.Availability.Message;
          }

          if (listing.DeliveryInfo && listing.DeliveryInfo.IsPrimeEligible) {
            defaultProduct.is_prime = listing.DeliveryInfo.IsPrimeEligible;
          }

          if (listing.MerchantInfo) {
            defaultProduct.fulfillment_type = listing.MerchantInfo.Type;
          }
        }

        // Extract images
        if (item.Images) {
          if (item.Images.Primary && item.Images.Primary.Medium) {
            defaultProduct.image_url = item.Images.Primary.Medium.URL;
          }
          
          if (item.Images.Variants) {
            defaultProduct.additional_image_urls = item.Images.Variants
              .map(variant => variant.Medium ? variant.Medium.URL : null)
              .filter(url => url !== null);
          }
        }

        // Extract brand, manufacturer, features
        if (item.ItemInfo) {
          if (item.ItemInfo.ByLineInfo && item.ItemInfo.ByLineInfo.Brand) {
            defaultProduct.brand = item.ItemInfo.ByLineInfo.Brand.DisplayValue;
          }
          
          if (item.ItemInfo.ManufactureInfo && item.ItemInfo.ManufactureInfo.ItemPartNumber) {
            defaultProduct.manufacturer = item.ItemInfo.ManufactureInfo.ItemPartNumber.DisplayValue;
          }
          
          if (item.ItemInfo.Features) {
            defaultProduct.features = item.ItemInfo.Features.DisplayValues || [];
          }
          
          if (item.ItemInfo.ProductInfo) {
            defaultProduct.specifications = item.ItemInfo.ProductInfo;
          }
          
          if (item.ItemInfo.Classifications && item.ItemInfo.Classifications.Binding) {
            defaultProduct.sub_category = item.ItemInfo.Classifications.Binding.DisplayValue;
          }
        }

        // Extract category from browse nodes
        if (item.BrowseNodeInfo && item.BrowseNodeInfo.BrowseNodes && item.BrowseNodeInfo.BrowseNodes.length > 0) {
          defaultProduct.category = item.BrowseNodeInfo.BrowseNodes[0].DisplayName;
        }

        // Extract ratings and reviews
        if (item.CustomerReviews) {
          if (item.CustomerReviews.StarRating) {
            defaultProduct.rating = parseFloat(item.CustomerReviews.StarRating.Value);
          }
          
          if (item.CustomerReviews.Count) {
            defaultProduct.total_reviews = item.CustomerReviews.Count;
          }
        }

        return defaultProduct;
      });

      // Store products in the database
      await this.storeProducts(products);

      return products;
    } catch (error) {
      console.error(`Error fetching products from Amazon ${this.countryCode}:`, error.message);
      throw new Error(`Failed to fetch products from Amazon ${this.countryCode}: ${error.message}`);
    }
  }

  // Store products in the database with country tagging
  async storeProducts(products) {
    const client = await getPool().connect();
    
    try {
      await client.query('BEGIN');
      
      // Set the country context for this operation
      await client.query('SET app.current_country = $1', [this.countryCode]);
      
      for (const product of products) {
        await client.query(
          `INSERT INTO agg.products (
             external_id, title, description, brand, manufacturer, category, sub_category,
             price, list_price, price_saved, discount_percentage, currency,
             product_url, features, specifications,
             availability, is_prime, fulfillment_type,
             image_url, additional_image_urls,
             rating, total_reviews, country, source, last_refreshed_at
           )
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, NOW())
           ON CONFLICT (source, external_id, country) 
           DO UPDATE SET 
             title = EXCLUDED.title,
             description = EXCLUDED.description,
             brand = EXCLUDED.brand,
             manufacturer = EXCLUDED.manufacturer,
             category = EXCLUDED.category,
             sub_category = EXCLUDED.sub_category,
             price = EXCLUDED.price,
             list_price = EXCLUDED.list_price,
             price_saved = EXCLUDED.price_saved,
             discount_percentage = EXCLUDED.discount_percentage,
             currency = EXCLUDED.currency,
             product_url = EXCLUDED.product_url,
             features = EXCLUDED.features,
             specifications = EXCLUDED.specifications,
             availability = EXCLUDED.availability,
             is_prime = EXCLUDED.is_prime,
             fulfillment_type = EXCLUDED.fulfillment_type,
             image_url = EXCLUDED.image_url,
             additional_image_urls = EXCLUDED.additional_image_urls,
             rating = EXCLUDED.rating,
             total_reviews = EXCLUDED.total_reviews,
             updated_at = NOW(),
             last_refreshed_at = NOW()`,
          [
            product.external_id,
            product.title,
            product.description,
            product.brand,
            product.manufacturer,
            product.category,
            product.sub_category,
            product.price,
            product.list_price,
            product.price_saved,
            product.discount_percentage,
            product.currency || 'GBP', // Explicitly set currency rather than relying on default
            product.product_url,
            product.features,
            product.specifications,
            product.availability,
            product.is_prime,
            product.fulfillment_type,
            product.image_url,
            product.additional_image_urls,
            product.rating,
            product.total_reviews,
            this.countryCode, // Explicitly set country rather than relying on default
            this.sourceName
          ]
        );
        
        // Also insert or update in the affiliate-specific table with country tag
        await client.query(
          `INSERT INTO aff.affiliate_products (
             product_id,
             affiliate_code,
             country,
             external_id,
             product_url,
             price,
             currency,
             last_checked
           )
           SELECT 
             p.id,
             $1,
             $2,
             $3,
             $4,
             $5,
             $6,
             NOW()
           FROM agg.products p
           WHERE p.external_id = $3 AND p.country = $2
           ON CONFLICT (product_id, affiliate_code, country) 
           DO UPDATE SET 
             product_url = EXCLUDED.product_url,
             price = EXCLUDED.price,
             currency = EXCLUDED.currency,
             last_checked = NOW()`,
          [
            this.affiliateCode,
            this.countryCode,
            product.external_id,
            product.product_url,
            product.price,
            product.currency
          ]
        );
      }
      
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      console.error(`Database error storing ${this.sourceName} products:`, error);
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new AmazonService_UK();