const amazonService = require('../../src/services/amazonService');

// Mock the database pool with proper Jest functions
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
      connect: jest.fn().mockResolvedValue(mockClient)
    },
    _mockClient: mockClient // Expose mock client for test access
  };
});

describe('Database Integration', () => {
  let mockClient;
  
  beforeEach(() => {
    jest.clearAllMocks();
    // Get reference to the mock client directly from mock module
    mockClient = require('../../src/config/db')._mockClient;
  });

  describe('storeProducts', () => {
    it('should store products in a transaction', async () => {
      // Arrange
      const mockProducts = [{
        source: 'Amazon UK',
        external_id: 'B08X12345',
        title: 'Test Product',
        brand: 'Test Brand',
        price: 99.99,
        currency: 'GBP',
      }];

      // Act
      await amazonService.storeProducts(mockProducts);

      // Assert
      expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
      // Updated to match our new single-database architecture with country tagging
      expect(mockClient.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO agg.products'),
        expect.arrayContaining([
          'B08X12345'
        ])
      );
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
      expect(mockClient.release).toHaveBeenCalled();
    });

    it('should rollback transaction on error', async () => {
      // Arrange
      const mockProducts = [{
        source: 'Amazon UK',
        external_id: 'B08X12345',
        title: 'Test Product'
      }];
      
      const dbError = new Error('Database error');
      
      // Setup the mock to throw an error on INSERT
      mockClient.query.mockImplementationOnce(() => Promise.resolve({})); // BEGIN
      mockClient.query.mockImplementationOnce(() => Promise.resolve({})); // SET app.current_country
      mockClient.query.mockImplementationOnce(() => { throw dbError; });  // INSERT
      mockClient.query.mockImplementationOnce(() => Promise.resolve({})); // ROLLBACK

      // Act & Assert
      await expect(amazonService.storeProducts(mockProducts)).rejects.toThrow(dbError);
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
      expect(mockClient.release).toHaveBeenCalled();
    });
  });
});