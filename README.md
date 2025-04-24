# Product API

A Node.js API for fetching products from Amazon India and Flipkart using their respective affiliate programs.

## Features

- Search products on Amazon India using the Product Advertising API 5.0
- Search products on Flipkart using the Flipkart Affiliate API
- Stores product data in PostgreSQL database
- Containerized with Docker and Docker Compose

## Prerequisites

- Node.js (14.x or later)
- Docker and Docker Compose
- Amazon Product Advertising API credentials
- Flipkart Affiliate API credentials

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

3. Edit the `.env` file with your actual credentials for Amazon and Flipkart APIs.

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

### Amazon Product Search

```
GET /api/amazon/search?q=<keyword>
```

Example:
```
GET /api/amazon/search?q=smartphone
```

### Flipkart Product Search

```
GET /api/flipkart/search?q=<keyword>
```

Example:
```
GET /api/flipkart/search?q=laptop
```

## Database Schema

```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  source VARCHAR(50) NOT NULL,
  external_id VARCHAR(100) NOT NULL,
  title TEXT,
  price NUMERIC,
  currency VARCHAR(3),
  image_url TEXT,
  retrieved_at TIMESTAMP DEFAULT now(),
  UNIQUE(source, external_id)
);
```

## Troubleshooting

- If the Flipkart API call fails, check your affiliate credentials and network connectivity
- If the database connection fails, ensure the PostgreSQL container is running and healthy

## License

MIT