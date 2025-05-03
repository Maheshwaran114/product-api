import fetch from 'node-fetch';

export async function fetchFnacFr(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.fnac.com/v1/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.FNAC_FR_API_KEY}` }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'Fnac France',
    external_id: item.id,
    title: item.title,
    price: item.price.amount,
    currency: 'EUR',
    image_url: item.imageUrl,
    detail_page_url: item.productUrl,
    description: item.description,
    country: 'FR'
  }));
}