import fetch from 'node-fetch';

export async function fetchAmazonFr(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.amazon.fr/paapi5/searchitems?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.AMAZON_FR_API_KEY}` }
  });
  const data = await res.json();
  return data.items.map(item => ({
    source: 'Amazon France',
    external_id: item.id,
    title: item.title,
    price: item.price.amount,
    currency: 'EUR',
    image_url: item.image,
    detail_page_url: item.detailPageUrl,
    description: item.description,
    country: 'FR'
  }));
}