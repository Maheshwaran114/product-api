const request = require('supertest');
const SwaggerParser = require('swagger-parser');
const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const path = require('path');
const axios = require('axios');
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

// Import app AFTER mocking dependencies
const { app } = require('../../src/app');

describe('API Contract Tests', () => {
  let apiSpec;
  let ajv;

  beforeAll(async () => {
    // Parse and validate the OpenAPI document
    apiSpec = await SwaggerParser.dereference(path.join(__dirname, '../../openapi.yaml'));
    
    // Initialize Ajv validator with configuration to handle OpenAPI extensions
    ajv = new Ajv({ 
      allErrors: true,
      strict: false, // Allow unknown keywords like 'example'
      strictSchema: false
    });
    addFormats(ajv);
  });

  // Helper function to clean schema of OpenAPI-specific properties
  const cleanSchema = (schema) => {
    // Make a deep copy of the schema
    const cleanedSchema = JSON.parse(JSON.stringify(schema));
    
    // Remove OpenAPI keywords that aren't part of JSON Schema
    const removeOpenAPIKeywords = (obj) => {
      if (!obj || typeof obj !== 'object') return;
      
      // List of OpenAPI-specific keywords to remove
      const openAPIKeywords = ['example', 'examples', 'xml', 'externalDocs'];
      
      openAPIKeywords.forEach(keyword => {
        if (Object.prototype.hasOwnProperty.call(obj, keyword)) {
          delete obj[keyword];
        }
      });
      
      // Process nested objects and arrays
      Object.values(obj).forEach(value => {
        if (value && typeof value === 'object') {
          removeOpenAPIKeywords(value);
        }
      });
    };
    
    removeOpenAPIKeywords(cleanedSchema);
    return cleanedSchema;
  };

  // Helper function to validate response against schema
  const validateResponse = (response, operationPath, statusCode) => {
    const pathObj = apiSpec.paths[operationPath];
    if (!pathObj) {
      throw new Error(`Path ${operationPath} not found in OpenAPI spec`);
    }
    
    const method = response.req.method.toLowerCase();
    const operation = pathObj[method];
    if (!operation) {
      throw new Error(`Operation ${method} not found for path ${operationPath}`);
    }

    const responseSpec = operation.responses[statusCode];
    if (!responseSpec) {
      throw new Error(`Response ${statusCode} not defined for ${operationPath}`);
    }

    if (responseSpec.content && responseSpec.content['application/json']) {
      const schema = responseSpec.content['application/json'].schema;
      const cleanedSchema = cleanSchema(schema);
      
      const validate = ajv.compile(cleanedSchema);
      const isValid = validate(response.body);
      
      if (!isValid) {
        console.error('Validation errors:', validate.errors);
      }
      
      expect(isValid).toBe(true);
    }
  };

  // Helper function to validate object against schema definition
  const validateAgainstSchema = (obj, schemaName) => {
    const schema = apiSpec.components.schemas[schemaName];
    if (!schema) {
      throw new Error(`Schema ${schemaName} not found in OpenAPI spec`);
    }

    const cleanedSchema = cleanSchema(schema);
    const validate = ajv.compile(cleanedSchema);
    const isValid = validate(obj);
    
    if (!isValid) {
      console.error('Validation errors:', validate.errors);
    }
    
    expect(isValid).toBe(true);
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Health Endpoint', () => {
    it('GET /health should satisfy the OpenAPI spec', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200)
        .expect('Content-Type', /json/);

      validateResponse(response, '/health', '200');
    });
  });

  describe('Amazon Search Endpoint', () => {
    it('GET /api/amazon/search with query should satisfy the OpenAPI spec', async () => {
      // Mock the Amazon API response
      axios.mockResolvedValueOnce(mockData.successResponse);
      
      const response = await request(app)
        .get('/api/amazon/search?q=laptop')
        .expect(200)
        .expect('Content-Type', /json/);

      validateResponse(response, '/api/amazon/search', '200');
    });

    it('GET /api/amazon/search without query should return 400 and satisfy the OpenAPI spec', async () => {
      const response = await request(app)
        .get('/api/amazon/search')
        .expect(400)
        .expect('Content-Type', /json/);

      validateResponse(response, '/api/amazon/search', '400');
    });

    it('GET /api/amazon/search with error should return 500 and satisfy the OpenAPI spec', async () => {
      // Mock the Amazon API to throw an error
      axios.mockRejectedValueOnce(new Error('API error'));
      
      const response = await request(app)
        .get('/api/amazon/search?q=error-test')
        .expect(500)
        .expect('Content-Type', /json/);

      validateResponse(response, '/api/amazon/search', '500');
    });
  });

  describe('Product Schema', () => {
    it('should validate the product schema against the OpenAPI spec', async () => {
      // Mock the Amazon API response
      axios.mockResolvedValueOnce(mockData.successResponse);
      
      const response = await request(app)
        .get('/api/amazon/search?q=laptop')
        .expect(200);
      
      // Check each product in the response conforms to the schema
      response.body.forEach(product => {
        validateAgainstSchema(product, 'Product');
      });
    });
  });
});