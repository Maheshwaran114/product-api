/**
 * Mock data representing responses from Amazon UK Product Advertising API
 */
module.exports = {
  successResponse: {
    data: {
      SearchResult: {
        Items: [
          {
            ASIN: 'B08X12345',
            DetailPageURL: 'https://www.amazon.co.uk/dp/B08X12345',
            ItemInfo: {
              Title: { DisplayValue: 'Apple MacBook Pro 16-inch' },
              Features: {
                DisplayValues: [
                  'Apple M1 Pro chip for a massive leap in CPU, GPU, and machine learning performance',
                  'Up to 17 hours of battery life',
                  '16-inch Liquid Retina XDR display with extreme dynamic range and contrast ratio',
                  'Three Thunderbolt 4 ports, HDMI port, SDXC card slot, MagSafe 3 port'
                ]
              },
              ByLineInfo: { Brand: { DisplayValue: 'Apple' } },
              ManufactureInfo: { ItemPartNumber: { DisplayValue: 'MK183B/A' } },
              ContentInfo: { Edition: { DisplayValue: '2021 Model' } },
              ProductInfo: {
                ItemDimensions: {
                  Height: { DisplayValue: 1.68, Unit: 'Centimeters' },
                  Width: { DisplayValue: 35.57, Unit: 'Centimeters' }
                }
              },
              Classifications: { Binding: { DisplayValue: 'Electronics' } }
            },
            BrowseNodeInfo: {
              BrowseNodes: [{ DisplayName: 'Laptops' }]
            },
            Images: {
              Primary: {
                Small: { URL: 'https://m.media-amazon.com/images/I/61aUBxqc5PL._AC_SL160_.jpg' },
                Medium: { URL: 'https://m.media-amazon.com/images/I/61aUBxqc5PL._AC_SL320_.jpg' },
                Large: { URL: 'https://m.media-amazon.com/images/I/61aUBxqc5PL._AC_SL500_.jpg' }
              },
              Variants: [
                {
                  Small: { URL: 'https://m.media-amazon.com/images/I/71YlH-4MUQL._AC_SL160_.jpg' },
                  Medium: { URL: 'https://m.media-amazon.com/images/I/71YlH-4MUQL._AC_SL320_.jpg' },
                  Large: { URL: 'https://m.media-amazon.com/images/I/71YlH-4MUQL._AC_SL500_.jpg' }
                },
                {
                  Small: { URL: 'https://m.media-amazon.com/images/I/61L5QgPvgML._AC_SL160_.jpg' },
                  Medium: { URL: 'https://m.media-amazon.com/images/I/61L5QgPvgML._AC_SL320_.jpg' },
                  Large: { URL: 'https://m.media-amazon.com/images/I/61L5QgPvgML._AC_SL500_.jpg' }
                }
              ]
            },
            Offers: {
              Listings: [
                {
                  Price: { Amount: 2399.00, Currency: 'GBP' },
                  SavingBasis: { Amount: 2499.00, Currency: 'GBP' },
                  Availability: { Message: 'In stock' },
                  DeliveryInfo: { IsPrimeEligible: true },
                  MerchantInfo: { Type: 'Amazon' }
                }
              ]
            },
            CustomerReviews: {
              Count: 1245,
              StarRating: { Value: 4.8 }
            }
          }
        ]
      }
    }
  },
  emptyResponse: {
    data: {
      SearchResult: {
        Items: []
      }
    }
  },
  errorResponse: {
    response: {
      status: 403,
      data: {
        errors: [
          {
            code: 'AccessDenied',
            message: 'Access to Product Advertising API data denied.'
          }
        ]
      }
    }
  }
};