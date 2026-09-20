import axios from 'axios';

const BASE_URL = 'https://api.sectors.app/v2';

const getHeaders = () => ({
  Authorization: process.env.SECTORS_API_KEY || '',
});

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

export async function getTransactionOverview(symbol: string) {
  const cleanSymbol = symbol.toUpperCase().replace('.JK', '');

  const response = await axios.get(`${BASE_URL}/daily/${cleanSymbol}/`, {
    headers: getHeaders(),
  });

  const history = Array.isArray(response.data) ? response.data as DailyRecord[] : [];
  const latest = history.at(-1) ?? null;
  const previous = history.at(-2) ?? null;

  const transactionCount = normalizeTransactionCount(latest);
  const previousTransactionCount = normalizeTransactionCount(previous);

  return {
    symbol: cleanSymbol,
    price: latest?.close ?? null,
    change: latest && previous?.close ? (latest.close - previous.close) / previous.close : null,
    latestDate: latest?.date ?? null,
    transactionCount,
    previousTransactionCount,
    volume: latest?.volume ?? null,
    value: latest?.value ?? null,
    history,
    source: 'Sectors Financial API',
  };
}

export async function getTransactionScreener(query = '') {
  const response = await axios.get(`${BASE_URL}/companies/`, {
    headers: getHeaders(),
    params: query.trim()
      ? { q: query.trim(), limit: 50 }
      : { order_by: 'symbol', limit: 50 },
  });

  const rows = Array.isArray(response.data?.results)
    ? (response.data.results as Array<{ symbol?: string; company_name?: string; name?: string }>)
    : [];

  const enriched = await Promise.all(
    rows.map(async (row) => {
      const symbol = String(row.symbol ?? '').replace('.JK', '');
      if (!symbol) return null;

      try {
        const detail = await getTransactionOverview(symbol);
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

export async function getTransactionDetailPage(symbol: string) {
  const detail = await getTransactionOverview(symbol);

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
