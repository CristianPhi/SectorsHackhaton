import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import axios from 'axios';

export type CompanyValuationInput = {
  price?: number | null;
  eps?: number | null;
  bookValue?: number | null;
};

export type ScreenerStockRow = {
  symbol: string;
  name?: string;
  price?: number | null;
  change?: number | null;
  transactionCount?: number | null;
  volume?: number | null;
  value?: number | null;
  peRatio?: number | null;
  pbv?: number | null;
  isCheap?: boolean;
  valuationScore?: number;
};

@Injectable()
export class SectorsService {
  private readonly baseUrl = 'https://api.sectors.app/v2';
  private readonly watchlist = [
    { symbol: 'BBCA', name: 'Bank Central Asia' },
    { symbol: 'TLKM', name: 'Telkom Indonesia' },
    { symbol: 'GOTO', name: 'GoTo Gojek Tokopedia' },
    { symbol: 'BBRI', name: 'Bank Rakyat Indonesia' },
    { symbol: 'BMRI', name: 'Bank Mandiri' },
  ];
  private readonly headers = {
    Authorization: process.env.SECTORS_API_KEY,
  };

  async screenCompanies(whereQuery: string, orderBy: string){
    try{
      const res = await axios.get(`${this.baseUrl}/companies/`, {
        headers: this.headers,
        params: { where: whereQuery, order_by: orderBy, limit: 5},
      });
      return JSON.stringify(res.data);
    }catch (err){
      return JSON.stringify({ error: (err as Error).message });
    }
  }
  async getCompanyOverview(symbol: string){
    try{
      const cleanSymbol = symbol.toUpperCase().replace('.JK','');
      const res = await axios.get(`${this.baseUrl}/company/report/${cleanSymbol}/`, {
        headers: this.headers,
      });
      return JSON.stringify(res.data);
    } catch (err){
      return JSON.stringify({ error: (err as Error).message });
    }
  }

  async getTechnicalIndicators(symbol: string) {
    try {
      const response = await axios.get(`https://api.sectors.app/v2/indonesia/technicals/${symbol}`, {
        headers: { Authorization: `Bearer ${process.env.SECTORS_API_KEY}` }
      });
      return response.data;
    } catch (error) {
      return { error: `Gagal mengambil data teknikal untuk ${symbol}` };
    }
  }

  async getMarketSnapshot() {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }

    const [results, index] = await Promise.all([
      Promise.all(
      this.watchlist.map(async (stock) => {
        try {
          const response = await axios.get(`${this.baseUrl}/daily/${stock.symbol}/`, {
            headers: this.headers,
          });
          const prices = Array.isArray(response.data) ? response.data : [];
          const latest = prices.at(-1);
          const previous = prices.at(-2);
          const change = latest && previous && previous.close
            ? (latest.close - previous.close) / previous.close
            : 0;

          return {
            ...stock,
            price: latest?.close ?? null,
            change,
            date: latest?.date ?? null,
          };
        } catch {
          return { ...stock, price: null, change: null, date: null };
        }
      }),
      ),
      this.getIndexSnapshot(),
    ]);

    return { data: results, ihsg: index, source: 'Sectors Financial API' };
  }

  async getSearchData(query = '') {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }

    const [companies, mostTraded, commodities, screener] = await Promise.all([
      this.getCompanies(query),
      this.getMostTraded(),
      this.getCommodityPrices(),
      this.getScreenerData({ q: query }),
    ]);

    const trending = this.sortStocksByTransaction(screener);

    return {
      companies,
      mostTraded,
      commodities,
      screener,
      trending,
      source: 'Sectors Financial API',
    };
  }

  async getScreenerData(filters: {
    q?: string;
    maxPe?: number;
    minPe?: number;
    maxPbv?: number;
    minPbv?: number;
    minTransaction?: number;
    minRoe?: number;
    maxRoe?: number;
    minPrice?: number;
    maxPrice?: number;
    sortBy?: 'transaction' | 'valuation' | 'price';
  } = {}) {
    const query = filters.q ?? '';
    const baseRows = await this.getCompanies(query);

    const rows = await Promise.all(
      baseRows.map(async (row) => {
        const symbol = String(row.symbol ?? '').replace('.JK', '');
        if (!symbol) return null;

        const report = await this.getCompanyReport(symbol);
        const detail = await this.getLatestDaily(symbol);
        const roe = this.extractReportNumber(report, ['roe', 'return_on_equity', 'roa', 'roe_percent']);
        const valuation = this.calculateValuationMetrics({
          price: detail.price,
          eps: this.extractReportNumber(report, ['eps', 'earnings_per_share', 'eps_basic', 'basic_eps']),
          bookValue: this.extractReportNumber(report, ['book_value', 'bookValue', 'equity_per_share', 'bvps']),
        });
        const [volume, value] = await Promise.all([
          this.getLatestVolume(symbol),
          this.getLatestValue(symbol),
        ]);
        const transactionCount = this.normalizeTransactionCountFromRows(await this.getDailyHistory(symbol));
        const stockName = typeof row.name === 'string' ? row.name : String(row.symbol ?? 'Unknown company');

        return {
          symbol,
          name: stockName,
          price: detail.price,
          change: detail.change,
          transactionCount,
          volume,
          value,
          peRatio: valuation.peRatio,
          pbv: valuation.pbv,
          roe,
          isCheap: valuation.isCheap,
          valuationScore: valuation.valuationScore,
          trendingRank: null,
        } as ScreenerStockRow & { roe?: number | null; trendingRank: number | null };
      }),
    );

    const filtered = rows.filter((row): row is ScreenerStockRow & { roe?: number | null; trendingRank: number | null } => !!row) as (ScreenerStockRow & { roe?: number | null; trendingRank: number | null })[];

    const withFilters = filtered.filter((row) => {
      const minPeOkay = typeof filters.minPe === 'number' ? (row.peRatio == null || row.peRatio >= filters.minPe) : true;
      const maxPeOkay = typeof filters.maxPe === 'number' ? (row.peRatio == null || row.peRatio <= filters.maxPe) : true;
      const minPbvOkay = typeof filters.minPbv === 'number' ? (row.pbv == null || row.pbv >= filters.minPbv) : true;
      const maxPbvOkay = typeof filters.maxPbv === 'number' ? (row.pbv == null || row.pbv <= filters.maxPbv) : true;
      const minRoeOkay = typeof filters.minRoe === 'number' ? (row.roe == null || row.roe >= filters.minRoe) : true;
      const maxRoeOkay = typeof filters.maxRoe === 'number' ? (row.roe == null || row.roe <= filters.maxRoe) : true;
      const minTransactionOkay = typeof filters.minTransaction === 'number' ? (row.transactionCount ?? 0) >= filters.minTransaction : true;
      const minPriceOkay = typeof filters.minPrice === 'number' ? (row.price ?? 0) >= filters.minPrice : true;
      const maxPriceOkay = typeof filters.maxPrice === 'number' ? (row.price ?? 0) <= filters.maxPrice : true;
      return minPeOkay && maxPeOkay && minPbvOkay && maxPbvOkay && minRoeOkay && maxRoeOkay && minTransactionOkay && minPriceOkay && maxPriceOkay;
    });

    const sorted = [...withFilters].sort((a, b) => {
      if (filters.sortBy === 'valuation') {
        return (b.valuationScore ?? 0) - (a.valuationScore ?? 0);
      }
      if (filters.sortBy === 'price') {
        return (b.price ?? 0) - (a.price ?? 0);
      }
      return (b.transactionCount ?? 0) - (a.transactionCount ?? 0);
    });

    return sorted.map((row, index) => ({
      ...row,
      trendingRank: index + 1,
    }));
  }

  async getTrendingStocks(options: { limit?: number; minTransaction?: number } = {}) {
    const limit = options.limit ?? 10;
    const minTransaction = options.minTransaction ?? 0;
    const screener = await this.getScreenerData({ minTransaction, sortBy: 'transaction' });
    return screener.slice(0, limit).map((stock, index) => ({
      ...stock,
      trendingRank: index + 1,
    }));
  }

  async getStockTransactions(symbol: string) {
    const cleanSymbol = symbol.toUpperCase().replace('.JK', '');
    const history = await this.getDailyHistory(cleanSymbol);
    const normalized = history.map((row) => ({
      date: row.date ?? null,
      close: row.close ?? null,
      volume: row.volume ?? null,
      value: row.value ?? null,
      transactionCount: this.normalizeTransactionCountFromRows([row]),
    }));

    const summary = normalized.at(-1) ?? null;
    return {
      symbol: cleanSymbol,
      totalTransactions: summary?.transactionCount ?? null,
      latestDate: summary?.date ?? null,
      history: normalized,
      source: 'Sectors Financial API',
    };
  }

  calculateValuationMetrics(input: CompanyValuationInput) {
    const price = Number(input.price ?? 0);
    const eps = Number(input.eps ?? 0);
    const bookValue = Number(input.bookValue ?? 0);

    const peRatio = eps > 0 ? price / eps : null;
    const pbv = bookValue > 0 ? price / bookValue : null;
    const isCheap = (peRatio == null || peRatio <= 15) && (pbv == null || pbv <= 1.5);

    const valuationScore = Number(
      ((peRatio != null ? Math.max(0, 15 - peRatio) : 0) + (pbv != null ? Math.max(0, 1.5 - pbv) : 0)) * 100,
    );

    return {
      peRatio,
      pbv,
      isCheap,
      valuationScore: Number.isFinite(valuationScore) ? valuationScore : 0,
    };
  }

  sortStocksByTransaction<T extends { transactionCount?: number | null }>(rows: T[]) {
    return [...rows].sort((a, b) => (b.transactionCount ?? 0) - (a.transactionCount ?? 0));
  }

  async getStockDetail(symbol: string) {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }
    const cleanSymbol = symbol.toUpperCase().replace('.JK', '');
    const [daily, report, technical] = await Promise.allSettled([
      axios.get(`${this.baseUrl}/daily/${cleanSymbol}/`, { headers: this.headers }),
      axios.get(`${this.baseUrl}/company/report/${cleanSymbol}/`, { headers: this.headers }),
      axios.get(`${this.baseUrl}/indonesia/technicals/${cleanSymbol}`, { headers: this.headers }),
    ]);
    const dailyData = daily.status === 'fulfilled' ? daily.value.data : [];
    const reportData = report.status === 'fulfilled' ? report.value.data : { error: 'Report fundamental tidak tersedia dari Sectors API' };
    const technicalData = technical.status === 'fulfilled' ? technical.value.data : { error: 'Data technical tidak tersedia dari Sectors API' };
    const prices = Array.isArray(dailyData) ? dailyData : [];
    const latest = prices.at(-1);
    const previous = prices.at(-2);
    return {
      symbol: cleanSymbol,
      price: latest?.close ?? null,
      change: latest && previous?.close ? (latest.close - previous.close) / previous.close : null,
      date: latest?.date ?? null,
      history: prices.slice(-30),
      report: reportData,
      technical: technicalData,
      source: 'Sectors Financial API',
    };
  }

  async getStockQuote(symbol: string) {
    const cleanSymbol = symbol.toUpperCase().replace('.JK', '');
    const quote = await this.getLatestDaily(cleanSymbol);
    return { symbol: cleanSymbol, ...quote, source: 'Sectors Financial API' };
  }

  private async getCompanies(query: string) {
    const rows: Record<string, unknown>[] = [];
    const pageSize = 200;
    let offset = 0;
    let hasNext = true;

    while (hasNext && rows.length < 1200) {
      const response = await axios.get(`${this.baseUrl}/companies/`, {
        headers: this.headers,
        params: query.trim()
          ? { q: query.trim(), limit: pageSize, offset }
          : { order_by: 'symbol', limit: pageSize, offset },
      });
      const page = Array.isArray(response.data?.results) ? response.data.results : [];
      rows.push(...page);
      hasNext = response.data?.pagination?.has_next === true && page.length > 0;
      offset += pageSize;
      if (query.trim()) break;
    }

    return Promise.all(rows.map(async (row: Record<string, unknown>) => {
      const symbol = String(row.symbol ?? '').replace('.JK', '');
      const latest = await this.getLatestDaily(symbol);
      return { symbol, name: row.company_name ?? row.name ?? 'Unknown company', price: latest.price, change: latest.change };
    }));
  }

  private async getLatestDaily(symbol: string) {
    try {
      const response = await axios.get(`${this.baseUrl}/daily/${symbol}/`, { headers: this.headers });
      const prices = Array.isArray(response.data) ? response.data : [];
      const latest = prices.at(-1);
      const previous = prices.at(-2);
      return {
        price: latest?.close ?? null,
        change: latest && previous?.close ? (latest.close - previous.close) / previous.close : null,
      };
    } catch {
      return { price: null, change: null };
    }
  }

  private async getDailyHistory(symbol: string) {
    try {
      const response = await axios.get(`${this.baseUrl}/daily/${symbol}/`, { headers: this.headers });
      return Array.isArray(response.data) ? response.data : [];
    } catch {
      return [];
    }
  }

  private normalizeTransactionCountFromRows(rows: Array<Record<string, unknown>>): number | null {
    const latest = rows.at(-1) as Record<string, unknown> | undefined;
    if (!latest) return null;

    const candidates = [
      latest.totalTransaction,
      latest.totalTransactions,
      latest.transaction,
      latest.trades,
      latest.totalTrades,
      latest.frequency,
      latest.volume,
    ];

    for (const value of candidates) {
      const parsed = Number(value);
      if (Number.isFinite(parsed) && parsed >= 0) {
        return parsed;
      }
    }

    return null;
  }

  private async getLatestVolume(symbol: string): Promise<number | null> {
    return this.getLatestMetric(symbol, 'volume');
  }

  private async getLatestValue(symbol: string): Promise<number | null> {
    return this.getLatestMetric(symbol, 'value');
  }

  private async getLatestMetric(symbol: string, field: 'volume' | 'value'): Promise<number | null> {
    try {
      const response = await axios.get(`${this.baseUrl}/daily/${symbol}/`, { headers: this.headers });
      const rows = Array.isArray(response.data) ? response.data : [];
      const latest = rows.at(-1) as Record<string, unknown> | undefined;
      if (!latest) return null;
      const value = Number(latest[field]);
      return Number.isFinite(value) ? value : null;
    } catch {
      return null;
    }
  }

  private async getCompanyReport(symbol: string): Promise<Record<string, unknown>> {
    try {
      const response = await axios.get(`${this.baseUrl}/company/report/${symbol}/`, { headers: this.headers });
      return response.data && typeof response.data === 'object' ? (response.data as Record<string, unknown>) : {};
    } catch {
      return {};
    }
  }

  private extractReportNumber(report: Record<string, unknown>, keys: string[]): number | null {
    for (const key of keys) {
      const value = report[key] ?? report[key.toLowerCase()] ?? report[key.toUpperCase()];
      const parsed = Number(value);
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }

    return null;
  }

  private async getMostTraded() {
    const response = await axios.get(`${this.baseUrl}/most-traded/`, {
      headers: this.headers,
      params: { n_stock: 10 },
    });
    const dates = Object.keys(response.data ?? {}).sort();
    const latest = dates.at(-1);
    const rows = latest ? response.data[latest] : [];
    return (Array.isArray(rows) ? rows : []).map((row: Record<string, unknown>) => ({
      symbol: String(row.symbol ?? '').replace('.JK', ''),
      name: row.company_name ?? 'Unknown company',
      price: row.price ?? null,
      volume: row.volume ?? null,
      date: latest ?? null,
    }));
  }

  private async getCommodityPrices() {
    const names = ['Gold', 'Coal', 'Nickel', 'Copper'];
    return Promise.all(names.map(async (name) => {
      try {
        const response = await axios.get(`${this.baseUrl}/mining/commodities/${name}/price/`, {
          headers: this.headers,
        });
        const rows = Array.isArray(response.data) ? response.data : [];
        const latest = rows.at(-1);
        return { name, price: latest?.price_usd_per_ton ?? null, date: latest?.date ?? null };
      } catch {
        return { name, price: null, date: null };
      }
    }));
  }

  private async getIndexSnapshot() {
    try {
      const response = await axios.get(`${this.baseUrl}/index-daily/ihsg/`, {
        headers: this.headers,
      });
      const prices = Array.isArray(response.data) ? response.data : [];
      const latest = prices.at(-1);
      const previous = prices.at(-2);
      const change = latest && previous && previous.price
        ? (latest.price - previous.price) / previous.price
        : 0;
      return { price: latest?.price ?? null, change, date: latest?.date ?? null };
    } catch {
      return { price: null, change: null, date: null };
    }
  }
}
