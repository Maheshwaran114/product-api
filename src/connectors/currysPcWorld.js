import fetch from 'node-fetch';

export async function fetchCurrysPcWorld(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.currys.co.uk/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.CURRYS_UK_API_KEY}` }
  });
  const data = await res.json();
  return data.items.map(item => ({
    source: 'Currys PC World',
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