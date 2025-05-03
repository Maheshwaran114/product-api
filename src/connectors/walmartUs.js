import fetch from 'node-fetch';

export async function fetchWalmartUs(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.walmart.com/v3/items/search?query=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.WALMART_US_API_KEY}` }
  });
  const data = await res.json();
  return data.items.map(item => ({
    source: 'Walmart US',
    external_id: item.id,
    title: item.title,
    price: item.price.amount,
    currency: item.price.currency,
    image_url: item.image,
    detail_page_url: item.detailPageUrl,
    description: item.description,
    country: 'US'
  }));
}