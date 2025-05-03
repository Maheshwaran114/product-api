const axios = require('axios');
const amazonService = require('../../src/services/amazonService');

// Mock external dependencies
jest.mock('axios');
jest.mock('../../src/config/db', () => {
  const mockClient = {
    query: jest.fn().mockResolvedValue({}),
    release: jest.fn(),
  };
  
  return {
    getPool: jest.fn().mockReturnValue({
      connect: jest.fn().mockResolvedValue(mockClient)
    }),
    pool: {
      connect: jest.fn().mockResolvedValue(mockClient),
    },
    _mockClient: mockClient // Expose for direct test access
  };
});

// Mock environment variables
process.env.AMAZON_TAG = 'test-tag-20';
process.env.AWS_ACCESS_KEY_ID = 'test-access-key';
process.env.AWS_SECRET_ACCESS_KEY = 'test-secret-key';

describe('Amazon Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('fetchProducts', () => {
    it('should return empty array when no items found', async () => {
      // Mock axios to return empty search result
      axios.mockResolvedValueOnce({
        data: {
          SearchResult: {
            Items: []
          }
        }
      });

      const result = await amazonService.fetchProducts('test');
      
      expect(result).toEqual([]);
      expect(axios).toHaveBeenCalledTimes(1);
    });

    it('should return formatted products when items are found', async () => {
      // Mock axios with sample product response
      const mockProduct = {
        ASIN: 'B08X12345',
        DetailPageURL: 'https://amazon.co.uk/dp/B08X12345',
        ItemInfo: {
          Title: { DisplayValue: 'Test Product' },
          Features: { DisplayValues: ['Feature 1', 'Feature 2'] },
          ByLineInfo: { Brand: { DisplayValue: 'Test Brand' } }
        },
        Images: {
          Primary: { Medium: { URL: 'https://test-image.jpg' } }
        },
        Offers: {
          Listings: [
            {
              Price: { Amount: 99.99, Currency: 'GBP' },
              DeliveryInfo: { IsPrimeEligible: true }
            }
          ]
        }
      };
      
      axios.mockResolvedValueOnce({
        data: {
          SearchResult: {
            Items: [mockProduct]
          }
        }
      });

      const result = await amazonService.fetchProducts('test');
      
      expect(result).toHaveLength(1);
      expect(result[0].external_id).toBe('B08X12345');
      expect(result[0].title).toBe('Test Product');
      expect(result[0].brand).toBe('Test Brand');
      expect(result[0].price).toBe(99.99);
      expect(result[0].is_prime).toBe(true);
      // We're now mocking getPool instead of pool directly
      expect(require('../../src/config/db').getPool).toHaveBeenCalled();
    });
  });
});