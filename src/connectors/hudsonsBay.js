import fetch from 'node-fetch';

export async function fetchHudsonsBay(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.thebay.com/v1/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.HUDSONSBAY_CA_API_KEY}` }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: "Hudson's Bay",
    external_id: item.productId,
    title: item.title,
    price: item.price.value,
    currency: 'CAD',
    image_url: item.images[0],
    detail_page_url: item.productUrl,
    description: item.shortDescription,
    country: 'CA'
  }));
}