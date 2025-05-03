import fetch from 'node-fetch';

export async function fetchArgos(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.argos.co.uk/v1/products/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.ARGOS_UK_API_KEY}` }
  });
  const data = await res.json();
  return data.items.map(item => ({
    source: 'Argos',
    external_id: item.id,
    title: item.title,
    price: item.price.amount,
    currency: item.price.currency,
    image_url: item.image,
    detail_page_url: item.detailPageUrl,
    description: item.description,
    country: 'GB'
  }));
}