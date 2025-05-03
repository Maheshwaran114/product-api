const request = require('supertest');
const axios = require('axios');
const mockData = require('../mocks/amazonResponseMock');

// Mock the database connection
jest.mock('../../src/config/db', () => {
  const mockProducts = [];
  const mockClient = {
    query: jest.fn((text, params) => {
      // Simple mock implementation to simulate database operations
      if (text.includes('INSERT INTO products')) {
        const productData = {
          id: mockProducts.length + 1,
          source: params[0],
          external_id: params[1],
          title: params[2],
          brand: params[3],
          price: params[4],
          currency: params[5]
        };
        mockProducts.push(productData);
        return { rows: [productData] };
      } else if (text.includes('SELECT * FROM products')) {
        if (params && params[0]) {
          // Filter by external_id if provided
          return { rows: mockProducts.filter(p => p.external_id === params[0]) };
        }
        return { rows: mockProducts };
      } else if (text.includes('DELETE FROM products')) {
        mockProducts.length = 0;
        return { rowCount: 0 };
      } else if (text.includes('UPDATE products')) {
        // Find and update product by external_id
        const externalId = params[4]; // Assuming external_id is the 5th parameter
        const productIndex = mockProducts.findIndex(p => p.external_id === externalId);
        if (productIndex >= 0) {
          mockProducts[productIndex].title = params[0];
          mockProducts[productIndex].price = params[1];
          return { rowCount: 1 };
        }
        return { rowCount: 0 };
      }
      return { rows: [] };
    }),
    release: jest.fn(),
  };
  
  return {
    pool: {
      connect: jest.fn().mockResolvedValue(mockClient)
    },
    connectDB: jest.fn().mockResolvedValue(true),
    getPool: jest.fn().mockReturnValue({
      connect: jest.fn().mockResolvedValue(mockClient)
    })
  };
});

// Mock Amazon API calls
jest.mock('axios');

// Use a random port for testing to avoid conflicts
const getRandomPort = () => Math.floor(Math.random() * 10000) + 10000;
process.env.PORT = getRandomPort();

// Import app after setting PORT and mocking dependencies
const { app, startServer } = require('../../src/app');

describe('Amazon API E2E Tests', () => {
  let server;

  beforeAll(async () => {
    // Start server
    server = await startServer();
  });

  afterAll(() => {
    if (server && server.close) {
      server.close();
    }
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/amazon/search', () => {
    it('should search products and store them in the database', async () => {
      // Mock the Amazon API response
      axios.mockResolvedValueOnce(mockData.successResponse);

      // Call the API
      const response = await request(app)
        .get('/api/amazon/search?q=laptop')
        .expect(200)
        .expect('Content-Type', /json/);

      // Check that we got products back
      expect(response.body).toBeInstanceOf(Array);
      expect(response.body.length).toBeGreaterThan(0);

      // Verify that the database query was called
      const dbModule = require('../../src/config/db');
      const mockClient = await dbModule.pool.connect();
      
      expect(mockClient.query).toHaveBeenCalled();
      // Verify an insert query was called (meaning products were saved to the database)
      expect(mockClient.query.mock.calls.some(call => 
        typeof call[0] === 'string' && (call[0].includes('INSERT INTO products') || call[0].includes('INSERT INTO agg.products'))
      )).toBe(true);
    });

    it('should handle errors when search query is missing', async () => {
      const response = await request(app)
        .get('/api/amazon/search')
        .expect(400)
        .expect('Content-Type', /json/);

      expect(response.body).toHaveProperty('error');
    });

    it('should handle errors from Amazon API', async () => {
      // Mock the Amazon API to throw an error
      axios.mockRejectedValueOnce(new Error('API error'));
      
      const response = await request(app)
        .get('/api/amazon/search?q=error-test')
        .expect(500)
        .expect('Content-Type', /json/);

      expect(response.body).toHaveProperty('error');
    });
  });
});