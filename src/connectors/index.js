// Import all vendor-specific fetch functions
import { fetchAmazonUk } from './amazonUk.js';
import { fetchJohnLewis } from './johnLewis.js';
import { fetchCurrysPcWorld } from './currysPcWorld.js';
import { fetchEbayUk } from './ebayUk.js';
import { fetchAsos } from './asos.js';
import { fetchArgos } from './argos.js';

import { fetchAmazonUs } from './amazonUs.js';
import { fetchEbayUs } from './ebayUs.js';
import { fetchHomeDepot } from './homeDepot.js';
import { fetchTarget } from './target.js';
import { fetchWalmartUs } from './walmartUs.js';
import { fetchBestBuy } from './bestBuy.js';

import { fetchAmazonCa } from './amazonCa.js';
import { fetchWalmartCa } from './walmartCa.js';
import { fetchBestBuyCa } from './bestBuyCa.js';
import { fetchEbayCa } from './ebayCa.js';
import { fetchCanadianTire } from './canadianTire.js';
import { fetchHudsonsBay } from './hudsonsBay.js';

import { fetchZalandoDe } from './zalandoDe.js';
import { fetchOttoDe } from './ottoDe.js';
import { fetchAmazonDe } from './amazonDe.js';
import { fetchMediaMarktDe } from './mediaMarktDe.js';
import { fetchSaturnDe } from './saturnDe.js';
import { fetchNotebooksbilligerDe } from './notebooksbilligerDe.js';

import { fetchAmazonFr } from './amazonFr.js';
import { fetchFnacFr } from './fnacFr.js';
import { fetchCdiscountFr } from './cdiscountFr.js';
import { fetchDartyFr } from './dartyFr.js';
import { fetchCarrefourFr } from './carrefourFr.js';
import { fetchRueDuCommerceFr } from './rueDuCommerceFr.js';

// Country-specific aggregation functions
export async function runAllUk(keyword) {
  const results = [];
  try {
    results.push(...await fetchAmazonUk(keyword));
    results.push(...await fetchJohnLewis(keyword));
    results.push(...await fetchCurrysPcWorld(keyword));
    results.push(...await fetchEbayUk(keyword));
    results.push(...await fetchAsos(keyword));
    results.push(...await fetchArgos(keyword));
  } catch (error) {
    console.error(`Error in UK connectors: ${error.message}`);
  }
  return results;
}

export async function runAllUs(keyword) {
  const results = [];
  try {
    results.push(...await fetchAmazonUs(keyword));
    results.push(...await fetchEbayUs(keyword));
    results.push(...await fetchHomeDepot(keyword));
    results.push(...await fetchTarget(keyword));
    results.push(...await fetchWalmartUs(keyword));
    results.push(...await fetchBestBuy(keyword));
  } catch (error) {
    console.error(`Error in US connectors: ${error.message}`);
  }
  return results;
}

export async function runAllCa(keyword) {
  const results = [];
  try {
    results.push(...await fetchAmazonCa(keyword));
    results.push(...await fetchWalmartCa(keyword));
    results.push(...await fetchBestBuyCa(keyword));
    results.push(...await fetchEbayCa(keyword));
    results.push(...await fetchCanadianTire(keyword));
    results.push(...await fetchHudsonsBay(keyword));
  } catch (error) {
    console.error(`Error in CA connectors: ${error.message}`);
  }
  return results;
}

export async function runAllDe(keyword) {
  const results = [];
  try {
    results.push(...await fetchZalandoDe(keyword));
    results.push(...await fetchOttoDe(keyword));
    results.push(...await fetchAmazonDe(keyword));
    results.push(...await fetchMediaMarktDe(keyword));
    results.push(...await fetchSaturnDe(keyword));
    results.push(...await fetchNotebooksbilligerDe(keyword));
  } catch (error) {
    console.error(`Error in DE connectors: ${error.message}`);
  }
  return results;
}

export async function runAllFr(keyword) {
  const results = [];
  try {
    results.push(...await fetchAmazonFr(keyword));
    results.push(...await fetchFnacFr(keyword));
    results.push(...await fetchCdiscountFr(keyword));
    results.push(...await fetchDartyFr(keyword));
    results.push(...await fetchCarrefourFr(keyword));
    results.push(...await fetchRueDuCommerceFr(keyword));
  } catch (error) {
    console.error(`Error in FR connectors: ${error.message}`);
  }
  return results;
}

// Export all individual connector functions as well
export {
  fetchAmazonUk, fetchJohnLewis, fetchCurrysPcWorld, fetchEbayUk, fetchAsos, fetchArgos,
  fetchAmazonUs, fetchEbayUs, fetchHomeDepot, fetchTarget, fetchWalmartUs, fetchBestBuy,
  fetchAmazonCa, fetchWalmartCa, fetchBestBuyCa, fetchEbayCa, fetchCanadianTire, fetchHudsonsBay,
  fetchZalandoDe, fetchOttoDe, fetchAmazonDe, fetchMediaMarktDe, fetchSaturnDe, fetchNotebooksbilligerDe,
  fetchAmazonFr, fetchFnacFr, fetchCdiscountFr, fetchDartyFr, fetchCarrefourFr, fetchRueDuCommerceFr
};