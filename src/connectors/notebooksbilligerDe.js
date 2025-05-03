import fetch from 'node-fetch';

export async function fetchNotebooksbilligerDe(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.notebooksbilliger.de/v1/products/search?q=' + encodeURIComponent(keyword), {
    headers: { 'Authorization': `Bearer ${process.env.NOTEBOOKSBILLIGER_DE_API_KEY}` }
  });
  const data = await res.json();
  return data.products.map(item => ({
    source: 'Notebooksbilliger DE',
    external_id: item.id,
    title: item.name,
    price: item.price,
    currency: 'EUR',
    image_url: item.imageUrl,
    detail_page_url: item.productUrl,
    description: item.description,
    country: 'DE'
  }));
}