import fetch from 'node-fetch';

export async function fetchCanadianTire(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.canadiantire.ca/v1/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.CANADIANTIRE_CA_API_KEY}` }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'Canadian Tire',
    external_id: item.productId,
    title: item.name,
    price: item.price.regular,
    currency: 'CAD',
    image_url: item.image,
    detail_page_url: item.productUrl,
    description: item.shortDescription,
    country: 'CA'
  }));
}