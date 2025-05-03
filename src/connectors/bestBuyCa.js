import fetch from 'node-fetch';

export async function fetchBestBuyCa(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.bestbuy.ca/v1/products?format=json&apiKey=${process.env.BESTBUY_CA_API_KEY}&query=' + encodeURIComponent(keyword), {
    headers: { 'Accept': 'application/json' }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'Best Buy Canada',
    external_id: item.sku,
    title: item.name,
    price: item.salePrice,
    currency: 'CAD',
    image_url: item.image,
    detail_page_url: item.url,
    description: item.shortDescription,
    country: 'CA'
  }));
}