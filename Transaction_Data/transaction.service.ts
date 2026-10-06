const BASE_URL = 'https://api.sectors.app/v2';

export type SectorsApiOptions = {
  apiKey?: string;
};

function getApiKey(options: SectorsApiOptions = {}) {
  const environment = (globalThis as typeof globalThis & {
    process?: { env?: Record<string, string | undefined> };
  }).process?.env;
  const apiKey = options.apiKey ?? environment?.SECTORS_API_KEY;
  if (!apiKey) {
    throw new Error('SECTORS_API_KEY belum diatur di environment');
  }

  return apiKey;
}

async function getSectorsData<T>(path: string, options: SectorsApiOptions = {}) {
  const response = await fetch(`${BASE_URL}${path}`, {
    method: 'GET',
    headers: { Authorization: getApiKey(options) },
  });

  if (!response.ok) {
    throw new Error(`Sectors API request failed: ${response.status} ${response.statusText}`);
  }

  return response.json() as Promise<T>;
}

type DailyRecord = {
  date?: string | null;
  close?: number | null;
  volume?: number | null;
  value?: number | null;
  trades?: number | null;
  transaction?: number | null;
  totalTransaction?: number | null;
  totalTransactions?: number | null;
  totalTrades?: number | null;
  frequency?: number | null;
  [key: string]: unknown;
};

function normalizeTransactionCount(record: DailyRecord | null | undefined): number | null {
  if (!record) return null;

  const candidates = [
    record.totalTransaction,
    record.totalTransactions,
    record.transaction,
    record.trades,
    record.totalTrades,
    record.frequency,
    record.volume,
  ];

  for (const value of candidates) {
    const asNumber = Number(value);
    if (Number.isFinite(asNumber) && asNumber >= 0) {
      return asNumber;
    }
  }

  return null;
}

export async function getDailyFullUniverseClose(options: SectorsApiOptions = {}) {
  return getSectorsData('/close/?limit=20', options);
}

export async function getDailyTransactionData(
  symbol: string,
  options: SectorsApiOptions = {},
) {
  const cleanSymbol = symbol.toUpperCase().replace('.JK', '');
  return getSectorsData<DailyRecord[]>(`/daily/${encodeURIComponent(cleanSymbol)}/`, options);
}

export async function getIdxMarketSummary(options: SectorsApiOptions = {}) {
  return getSectorsData('/idx-total/', options);
}

export async function getDailyFullUniverseIndexClose(options: SectorsApiOptions = {}) {
  return getSectorsData('/index-daily/', options);
}

export async function getIndexDailyTransactionData(
  indexCode: string,
  options: SectorsApiOptions = {},
) {
  return getSectorsData(
    `/index-daily/${encodeURIComponent(indexCode)}/`,
    options,
  );
}

export async function getTransactionOverview(
  symbol: string,
  options: SectorsApiOptions = {},
) {
  const cleanSymbol = symbol.toUpperCase().replace('.JK', '');
  const data = await getDailyTransactionData(cleanSymbol, options);
  const history = Array.isArray(data) ? data : [];
  const latest = history.at(-1) ?? null;
  const previous = history.at(-2) ?? null;

  const transactionCount = normalizeTransactionCount(latest);
  const previousTransactionCount = normalizeTransactionCount(previous);

  return {
    symbol: cleanSymbol,
    price: latest?.close ?? null,
    change: latest?.close != null && previous?.close != null
      ? (latest.close - previous.close) / previous.close
      : null,
    latestDate: latest?.date ?? null,
    transactionCount,
    previousTransactionCount,
    volume: latest?.volume ?? null,
    value: latest?.value ?? null,
    history,
    source: 'Sectors Financial API',
  };
}

export async function getTransactionScreener(
  query = '',
  options: SectorsApiOptions = {},
) {
  const data = await getDailyFullUniverseClose(options);
  const rows = Array.isArray(data)
    ? data as Array<{ symbol?: string; company_name?: string; name?: string }>
    : Array.isArray((data as { results?: unknown })?.results)
      ? (data as { results: Array<{ symbol?: string; company_name?: string; name?: string }> }).results
      : [];
  const normalizedQuery = query.trim().toUpperCase();
  const filteredRows = normalizedQuery
    ? rows.filter((row) => String(row.symbol ?? '').toUpperCase().includes(normalizedQuery))
    : rows;

  const enriched = await Promise.all(
    filteredRows.map(async (row) => {
      const symbol = String(row.symbol ?? '').replace('.JK', '');
      if (!symbol) return null;

      try {
        const detail = await getTransactionOverview(symbol, options);
        return {
          symbol,
          name: row.company_name ?? row.name ?? 'Unknown company',
          price: detail.price,
          change: detail.change,
          transactionCount: detail.transactionCount,
          volume: detail.volume,
          value: detail.value,
        };
      } catch {
        return {
          symbol,
          name: row.company_name ?? row.name ?? 'Unknown company',
          price: null,
          change: null,
          transactionCount: null,
          volume: null,
          value: null,
        };
      }
    }),
  );

  return enriched.filter(Boolean);
}

export async function getTransactionDetailPage(
  symbol: string,
  options: SectorsApiOptions = {},
) {
  const detail = await getTransactionOverview(symbol, options);

  return {
    ...detail,
    transactions: detail.history.map((row) => ({
      date: row.date,
      transactionCount: normalizeTransactionCount(row),
      volume: row.volume ?? null,
      value: row.value ?? null,
      close: row.close ?? null,
    })),
  };
}
