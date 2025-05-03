const request = require('supertest');
const axios = require('axios');
const { pool } = require('../../src/config/db');
const { app } = require('../../src/app');
const mockData = require('../mocks/amazonResponseMock');

// Mock both the Amazon API and the database
jest.mock('axios');
jest.mock('../../src/config/db', () => {
  const mockClient = {
    query: jest.fn().mockResolvedValue({ rows: [] }),
    release: jest.fn(),
  };
  
  return {
    pool: {
      connect: jest.fn().mockResolvedValue(mockClient),
    },
    connectDB: jest.fn().mockResolvedValue(true)
  };
});

describe('Amazon API Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/amazon/search', () => {
    it('should return 400 if no query parameter is provided', async () => {
      const response = await request(app)
        .get('/api/amazon/search')
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should return products when a valid query is provided', async () => {
      // Mock the Amazon API response
      axios.mockResolvedValueOnce(mockData.successResponse);
      
      const response = await request(app)
        .get('/api/amazon/search?q=laptop')
        .expect('Content-Type', /json/)
        .expect(200);

      // Check if the response matches the expected format
      expect(response.body).toHaveLength(1);
      expect(response.body[0].external_id).toBe('B08X12345');
      expect(response.body[0].title).toBe('Apple MacBook Pro 16-inch');
      expect(response.body[0].brand).toBe('Apple');
      expect(response.body[0].price).toBe(2399);
      
      // In the test environment, we don't need to check database interactions
      // since we're mocking the amazonService response
    });

    it('should handle errors from the Amazon service', async () => {
      // Mock the Amazon API to throw an error
      axios.mockRejectedValueOnce(new Error('API error'));
      
      const response = await request(app)
        .get('/api/amazon/search?q=error-test')
        .expect('Content-Type', /json/)
        .expect(500);

      expect(response.body).toHaveProperty('error');
    });
  });
});