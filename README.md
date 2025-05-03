# Product API

A Node.js API for fetching products from Amazon UK using the Product Advertising API.

## Features

- Search products on Amazon UK using the Product Advertising API 5.0
- Stores product data in PostgreSQL database with country-based partitioning
- GDPR-compliant user data management with encryption
- Audit logging for all database changes
- Containerized with Docker and Docker Compose

## Prerequisites

- Node.js (14.x or later)
- Docker and Docker Compose
- Amazon Product Advertising API credentials (with UK marketplace access)

## Setup

1. Clone the repository:
   ```
   git clone <repository-url>
   cd product-api
   ```

2. Create a `.env` file based on `.env.example` and fill in your API credentials:
   ```
   cp .env.example .env
   ```

3. Edit the `.env` file with your actual credentials for Amazon API.

## Running the Application

### Using Docker Compose

Build and start the containers:
```
docker-compose up --build
```

The API will be available at http://localhost:3000

### Without Docker

1. Make sure you have a PostgreSQL database running and accessible
2. Update the `.env` file with your database connection details
3. Install dependencies:
   ```
   npm install
   ```
4. Start the application:
   ```
   npm start
   ```

## API Endpoints

### Amazon UK Product Search

```
GET /api/amazon/search?q=<keyword>
```

Example:
```
GET /api/amazon/search?q=smartphone
```

## Database Architecture

The database follows a modular schema design with the following components:

### Schemas

- `agg`: Aggregate product data with country-based partitioning
- `aff`: Affiliate-specific data with country-based partitioning
- `users`: GDPR-compliant user management
- `social`: Social engagement data
- `fin`: Financial transaction records
- `audit`: Comprehensive audit logging

### Key Design Features

1. **Country-based Partitioning**: Product tables are partitioned by country code for optimized query performance
2. **GDPR Compliance**: User data is encrypted, with immutable consent records
3. **Audit Logging**: All changes to sensitive data are tracked
4. **Automatic Timestamps**: `updated_at` columns are automatically maintained via triggers

### Primary Key Strategy

We use a composite primary key (`id`, `country`) for partitioned tables to support PostgreSQL's partitioning requirements. The `id` is a UUID generated using `gen_random_uuid()`.

## Recent Architecture Updates

The following gaps have been addressed:

1. **Timestamp Triggers**: Added automated triggers to update `updated_at` columns when records change
2. **Missing Columns**: Added `updated_at` to all tables that were missing it
3. **Data Freshness**: Added monitoring capability for data freshness
4. **Documentation**: Updated to reflect architectural decisions

## Next Steps

1. **Performance Testing**: Conduct load tests on partitioned tables to validate the partitioning strategy
2. **Monitoring Implementation**: Set up data freshness monitoring for all tables
3. **Encryption Key Management**: Implement a secure key rotation strategy for the encryption key
4. **Add Data Extraction Tools**: For GDPR data subject access requests
5. **API Rate Limiting**: Implement rate limiting for the Amazon API to stay within quotas

## Database Migration

Run migrations to set up the database:
```
npm run migrate
```

To seed sample data:
```
npm run seed
```

## Troubleshooting

- If the Amazon API call fails, check your Amazon Associate tag is valid for the UK marketplace
- If the database connection fails, ensure the PostgreSQL container is running and healthy

## License

MIT