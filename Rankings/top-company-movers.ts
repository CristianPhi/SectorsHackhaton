const API_URL = 'https://api.sectors.app/v2/companies/top-changes/';

type TopCompanyMoversOptions = {
  apiKey?: string;
};

export async function getTopCompanyMovers(options: TopCompanyMoversOptions = {}) {
  const apiKey = options.apiKey ?? process.env.SECTORS_API_KEY;
  if (!apiKey) {
    throw new Error('SECTORS_API_KEY belum diatur di environment');
  }

  const url = new URL(API_URL);
  url.searchParams.set('n_stock', '5');
  url.searchParams.set('classifications', 'all');
  url.searchParams.set('periods', 'all');
  url.searchParams.set('min_mcap_billion', '5000');

  const response = await fetch(url, {
    method: 'GET',
    headers: { Authorization: apiKey },
  });

  if (!response.ok) {
    throw new Error(`Top Company Movers request failed: ${response.status} ${response.statusText}`);
  }

  return response.json();
}
