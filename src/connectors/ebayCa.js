import fetch from 'node-fetch';

export async function fetchEbayCa(keyword) {
  // TODO: replace with real API endpoint and env var keys
  const res = await fetch('https://api.ebay.com/buy/browse/v1/item_summary/search?q=' + encodeURIComponent(keyword) + '&filter=deliveryCountry:CA', {
    headers: { 'Authorization': `Bearer ${process.env.EBAY_CA_API_KEY}` }
  });
  const data = await res.json();
  return data.items.map(item => ({
    source: 'eBay Canada',
    external_id: item.id,
    title: item.title,
    price: item.price.amount,
    currency: item.price.currency || 'CAD',
    image_url: item.image,
    detail_page_url: item.detailPageUrl,
    description: item.description,
    country: 'CA'
  }));
}