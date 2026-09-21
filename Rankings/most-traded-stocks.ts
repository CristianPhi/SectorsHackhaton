const API_URL = 'https://api.sectors.app/v2/most-traded/';

type MostTradedStocksOptions = {
  apiKey?: string;
};

export async function getMostTradedStocks(options: MostTradedStocksOptions = {}) {
  const apiKey = options.apiKey ?? process.env.SECTORS_API_KEY;
  if (!apiKey) {
    throw new Error('SECTORS_API_KEY belum diatur di environment');
  }

  const url = new URL(API_URL);
  url.searchParams.set('n_stock', '5');

  const response = await fetch(url, {
    method: 'GET',
    headers: { Authorization: apiKey },
  });

  if (!response.ok) {
    throw new Error(`Most Traded Stocks request failed: ${response.status} ${response.statusText}`);
  }

  return response.json();
}
