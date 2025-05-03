import fetch from 'node-fetch';

export async function fetchCdiscountFr(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.cdiscount.com/v1/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.CDISCOUNT_FR_API_KEY}` }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'Cdiscount',
    external_id: item.id,
    title: item.name,
    price: item.price,
    currency: 'EUR',
    image_url: item.imageUrl,
    detail_page_url: item.productUrl,
    description: item.description,
    country: 'FR'
  }));
}