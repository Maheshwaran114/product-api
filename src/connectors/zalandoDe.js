import fetch from 'node-fetch';

export async function fetchZalandoDe(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.zalando.de/search?query=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.ZALANDO_DE_API_KEY}` }
  });
  const data = await res.json();
  return data.articles.map(item => ({
    source: 'Zalando DE',
    external_id: item.id,
    title: item.name,
    price: item.price.amount,
    currency: 'EUR',
    image_url: item.media.images[0].url,
    detail_page_url: item.url,
    description: item.description,
    country: 'DE'
  }));
}