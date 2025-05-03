import fetch from 'node-fetch';

export async function fetchDartyFr(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.darty.com/v1/products/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.DARTY_FR_API_KEY}` }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'Darty',
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