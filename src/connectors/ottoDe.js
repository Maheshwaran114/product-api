import fetch from 'node-fetch';

export async function fetchOttoDe(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.otto.de/v1/products/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.OTTO_DE_API_KEY}` }
  });
  const data = await res.json();
  return data.items.map(item => ({
    source: 'Otto DE',
    external_id: item.id,
    title: item.title,
    price: item.price.amount,
    currency: 'EUR',
    image_url: item.imageUrl,
    detail_page_url: item.productUrl,
    description: item.description,
    country: 'DE'
  }));
}