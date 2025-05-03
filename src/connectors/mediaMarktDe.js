import fetch from 'node-fetch';

export async function fetchMediaMarktDe(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.mediamarkt.de/v1/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.MEDIAMARKT_DE_API_KEY}` }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'MediaMarkt DE',
    external_id: item.id,
    title: item.name,
    price: item.price.currentPrice,
    currency: 'EUR',
    image_url: item.images[0].url,
    detail_page_url: item.url,
    description: item.shortDescription,
    country: 'DE'
  }));
}