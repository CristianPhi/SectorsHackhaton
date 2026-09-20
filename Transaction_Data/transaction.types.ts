export type TransactionMetric = {
  value?: number | null;
  volume?: number | null;
  trades?: number | null;
  transaction?: number | null;
  totalTransaction?: number | null;
  totalTransactions?: number | null;
  totalTrades?: number | null;
  frequency?: number | null;
};

export type StockDailyRecord = {
  date?: string | null;
  symbol?: string | null;
  close?: number | null;
  open?: number | null;
  high?: number | null;
  low?: number | null;
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

export type StockTransactionSummary = {
  symbol: string;
  name?: string;
  price?: number | null;
  change?: number | null;
  latestDate?: string | null;
  transactionCount?: number | null;
  volume?: number | null;
  value?: number | null;
  history?: StockDailyRecord[];
  source: string;
};

export type StockScreenerRow = {
  symbol: string;
  name?: string;
  price?: number | null;
  change?: number | null;
  transactionCount?: number | null;
  volume?: number | null;
  value?: number | null;
};
