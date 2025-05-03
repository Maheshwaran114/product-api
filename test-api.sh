#!/bin/bash
# Simple script to test the Amazon UK API endpoints

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:3000/health | jq .

# Test Amazon search endpoint with a keyword
echo -e "\nTesting Amazon UK search with keyword 'laptop'..."
curl -s "http://localhost:3000/api/amazon/search?q=laptop" | jq .

# If you want to test with different keywords:
# echo -e "\nTesting Amazon UK search with keyword 'smartphone'..."
# curl -s "http://localhost:3000/api/amazon/search?q=smartphone" | jq .