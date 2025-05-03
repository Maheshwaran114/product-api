import fetch from 'node-fetch';

export async function fetchBestBuy(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.bestbuy.com/v1/products?format=json&apiKey=${process.env.BESTBUY_US_API_KEY}&query=' + encodeURIComponent(keyword), {
    headers: { 'Accept': 'application/json' }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'Best Buy',
    external_id: item.sku,
    title: item.name,
    price: item.salePrice,
    currency: 'USD',
    image_url: item.image,
    detail_page_url: item.url,
    description: item.shortDescription,
    country: 'US'
  }));
}