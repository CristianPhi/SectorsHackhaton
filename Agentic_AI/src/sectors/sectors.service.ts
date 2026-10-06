import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import axios, { type AxiosRequestConfig } from 'axios';

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
  private readonly responseCache = new Map<string, { data: unknown; expiresAt: number }>();
  private readonly pendingRequests = new Map<string, Promise<unknown>>();
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
      const data = await this.getSectorsData<Record<string, unknown>>(`${this.baseUrl}/companies/`, {
        headers: this.headers,
        params: { where: whereQuery, order_by: orderBy, limit: 5},
      });
      return JSON.stringify(data);
    } catch (error) {
      return JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }
  async getCompanyOverview(symbol: string){
    try{
      const cleanSymbol = symbol.toUpperCase().replace('.JK','');
      return JSON.stringify(await this.fetchCompanyReport(cleanSymbol));
    } catch (err){
      return JSON.stringify({ error: (err as Error).message });
    }
  }

  async getTechnicalIndicators(symbol: string) {
    if (!process.env.SECTORS_API_KEY) {
      return {
        symbol: symbol.toUpperCase(),
        note: 'Data teknikal dibatasi karena API key Sectors belum aktif. Gunakan analisis lokal untuk screening awal.',
        indicators: {},
      };
    }

    try {
      return await this.getSectorsData(`https://api.sectors.app/v2/indonesia/technicals/${symbol}`, {
        headers: { Authorization: `Bearer ${process.env.SECTORS_API_KEY}` }
      });
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
          const prices = await this.getSectorsData<Record<string, any>[]>(`${this.baseUrl}/daily/${stock.symbol}/`, {
            headers: this.headers,
          });
          const dailyRows = Array.isArray(prices) ? prices : [];
          const latest = dailyRows.at(-1);
          const previous = dailyRows.at(-2);
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

  async getLocalStocks() {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }
    const stocks = await this.getCompanies('');
    return stocks.map((stock) => this.toClientStock(stock));
  }

  async searchStocks(query = '', filters: {
    maxPe?: number;
    maxPbv?: number;
    minTransaction?: number;
    sortBy?: 'transaction' | 'valuation' | 'price';
  } = {}) {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }

    const q = query.trim();
    const stocks = await this.getCompanies(q);

    const filtered = stocks.filter((stock: { symbol: string; name: string; price: number | null; change: number | null }) => {
      if (!q) return true;
      const symbol = String(stock.symbol ?? '').toLowerCase();
      const name = String(stock.name ?? '').toLowerCase();
      return symbol.includes(q.toLowerCase()) || name.includes(q.toLowerCase());
    });

    const sorted = [...filtered].sort((a, b) => {
      if (filters.sortBy === 'price') {
        return (b.price ?? 0) - (a.price ?? 0);
      }
      return (b.change ?? 0) - (a.change ?? 0);
    });

    return sorted.map((stock) => this.toClientStock(stock));
  }

  async getFavoriteStocks() {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }

    const favorites = ['BBCA', 'TLKM', 'BBRI', 'BMRI'];
    const stocks = await this.getCompanies('');
    return stocks
      .filter((stock) => favorites.includes(stock.symbol))
      .map((stock) => this.toClientStock(stock));
  }

  async getRecentlySearched() {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }

    const order = ['BBRI', 'BMRI', 'BBCA', 'TLKM'];
    const stocks = await this.getCompanies('');
    return order
      .map((ticker) => stocks.find((stock) => stock.symbol === ticker))
      .filter((stock): stock is { symbol: string; name: string; price: number | null; change: number | null } => Boolean(stock))
      .map((stock) => this.toClientStock(stock));
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
      this.getSectorsData<unknown>(`${this.baseUrl}/daily/${cleanSymbol}/`, { headers: this.headers }),
      this.fetchCompanyReport(cleanSymbol),
      this.getSectorsData<unknown>(`${this.baseUrl}/indonesia/technicals/${cleanSymbol}`, { headers: this.headers }),
    ]);

    const dailyData = daily.status === 'fulfilled' ? daily.value : [];
    const reportData = report.status === 'fulfilled' ? report.value : {};
    let technicalData = technical.status === 'fulfilled' ? technical.value : {};
    if (technical.status === 'rejected') {
      try {
        technicalData = await this.getSectorsData<unknown>(`${this.baseUrl}/technicals/${cleanSymbol}/`, {
          headers: this.headers,
        });
      } catch {
        technicalData = {};
      }
    }
    const technicalIndicators = (technicalData as { indicators?: unknown } | null)?.indicators;
    const prices = Array.isArray(dailyData) ? dailyData : [];
    const latest = prices.at(-1);
    const previous = prices.at(-2);
    const price = latest?.close ?? null;
    const changePct = latest && previous?.close ? ((latest.close - previous.close) / previous.close) * 100 : null;
    const sparkline = prices.slice(-14).map((row: any) => Number(row.close ?? row.price ?? 0)).filter((value) => Number.isFinite(value));

    const overview = reportData && typeof reportData === 'object' && 'overview' in reportData && reportData.overview && typeof reportData.overview === 'object'
      ? (reportData.overview as Record<string, any>)
      : {};
    const valuation = reportData && typeof reportData === 'object' && 'valuation' in reportData && reportData.valuation && typeof reportData.valuation === 'object'
      ? (reportData.valuation as Record<string, any>)
      : {};

    const marketCap = Number(
      reportData?.market_cap ??
      reportData?.marketCap ??
      overview?.market_cap ??
      overview?.marketCap ??
      0,
    );

    const fallbackTechnical = [
      {
        name: 'Trend',
        value: changePct == null ? 'N/A' : (changePct >= 0 ? 'Uptrend' : 'Downtrend'),
        interpretation: changePct == null
          ? 'Data pergerakan tidak tersedia.'
          : `${changePct >= 0 ? 'Harga menguat' : 'Harga melemah'} ${Math.abs(changePct).toFixed(2)}% dalam periode terakhir.`,
        signal: changePct == null ? 'netral' : changePct >= 0 ? 'bullish' : 'bearish',
      },
      {
        name: 'Range',
        value: sparkline.length > 1 ? `${Math.min(...sparkline).toFixed(0)} - ${Math.max(...sparkline).toFixed(0)}` : 'N/A',
        interpretation: 'Rentang harga terakhir menunjukkan volatilitas pasar yang sedang terjadi.',
        signal: 'netral',
      },
      {
        name: 'Momentum',
        value: price == null ? 'N/A' : `Rp ${Number(price).toLocaleString('id-ID')}`,
        interpretation: 'Harga terakhir menjadi referensi momentum saham saat ini.',
        signal: changePct != null && changePct >= 0 ? 'bullish' : 'bearish',
      },
    ];

    const fallbackFundamental = [
      {
        name: 'Market Cap',
        value: marketCap > 0 ? `Rp ${Number(marketCap).toLocaleString('id-ID')}` : 'N/A',
        interpretation: 'Kapitalisasi pasar perusahaan pada pasar saat ini.',
        signal: marketCap > 0 ? 'bullish' : 'netral',
      },
      {
        name: 'Sector',
        value: String(reportData?.sector ?? overview?.sector ?? 'Sektor utama'),
        interpretation: 'Sektor utama perusahaan sebagai konteks industri.',
        signal: 'netral',
      },
      {
        name: 'P/B',
        value: valuation?.pb ?? valuation?.pbv ?? valuation?.pb_mrq ?? 'N/A',
        interpretation: 'Rasio nilai buku relatif terhadap harga saham.',
        signal: 'netral',
      },
    ];

    const description = `Saham ${cleanSymbol} ditampilkan berdasarkan data real-time dari Sectors API, mencerminkan pergerakan harga harian, indikator teknikal, dan laporan fundamental terbaru.`;

    return {
      stock: {
        ticker: cleanSymbol,
        name: String(reportData?.company_name ?? reportData?.name ?? overview?.company_name ?? cleanSymbol),
        sector: String(reportData?.sector ?? overview?.sector ?? overview?.industry ?? 'Sektor utama'),
        price: Number(price ?? 0),
        changePercent: Number(changePct ?? 0),
        changeAbsolute: Number(price != null && changePct != null ? price * (changePct / 100) : 0),
      },
      description,
      marketCap: Number(marketCap ?? 0),
      dayHigh: Number(sparkline.length > 0 ? Math.max(...sparkline) : price ?? 0),
      dayLow: Number(sparkline.length > 0 ? Math.min(...sparkline) : price ?? 0),
      sparkline,
      teknikal: Array.isArray(technicalIndicators)
        ? technicalIndicators.slice(0, 3)
        : Array.isArray(technicalData)
          ? technicalData.slice(0, 3)
          : fallbackTechnical,
      fundamental: Array.isArray(reportData?.metrics)
        ? reportData.metrics.slice(0, 3)
        : Array.isArray(reportData?.financials)
          ? reportData.financials.slice(0, 3)
          : fallbackFundamental,
      berita: Array.isArray(reportData?.news) ? reportData.news.slice(0, 3) : [],
      source: 'Sectors Financial API',
    };
  }

  async getStockQuote(symbol: string) {
    const cleanSymbol = symbol.toUpperCase().replace('.JK', '');
    const quote = await this.getLatestDaily(cleanSymbol);
    return { symbol: cleanSymbol, ...quote, source: 'Sectors Financial API' };
  }

  private async getCompanies(query: string): Promise<Array<{ symbol: string; name: string; price: number | null; change: number | null }>> {
    const rows: Record<string, unknown>[] = [];
    const pageSize = query.trim() ? 20 : 50;
    let offset = 0;
    let hasNext = true;

    while (hasNext && rows.length < pageSize) {
      const data = await this.getSectorsData<Record<string, any>>(`${this.baseUrl}/companies/`, {
        headers: this.headers,
        params: query.trim()
          ? { q: query.trim(), limit: pageSize, offset }
          : { order_by: 'symbol', limit: pageSize, offset },
      });
      const page = Array.isArray(data?.results) ? data.results as Record<string, unknown>[] : [];
      rows.push(...page);
      hasNext = data?.pagination?.has_next === true && page.length > 0;
      offset += pageSize;
      if (query.trim()) break;
    }

    return Promise.all(rows.map(async (row: Record<string, unknown>) => {
      const symbol = String(row.symbol ?? '').replace('.JK', '');
      const latest = await this.getLatestDaily(symbol);
      const companyName = typeof row.company_name === 'string'
        ? row.company_name
        : typeof row.name === 'string'
          ? row.name
          : 'Unknown company';

      return {
        symbol,
        name: companyName,
        price: latest.price,
        change: latest.change,
      };
    }));
  }

  private toClientStock(stock: { symbol: string; name: string; price: number | null; change: number | null }) {
    const price = Number(stock.price ?? 0);
    const change = Number(stock.change ?? 0);
    return {
      ticker: stock.symbol,
      name: stock.name,
      sector: 'IDX',
      price: Number.isFinite(price) ? price : 0,
      changePercent: Number.isFinite(change) ? change * 100 : 0,
      changeAbsolute: Number.isFinite(price * change) ? price * change : 0,
    };
  }

  private async getLatestDaily(symbol: string) {
    try {
      const data = await this.getSectorsData<unknown>(`${this.baseUrl}/daily/${symbol}/`, { headers: this.headers });
      const prices = Array.isArray(data) ? data : [];
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
      const data = await this.getSectorsData<unknown>(`${this.baseUrl}/daily/${symbol}/`, { headers: this.headers });
      return Array.isArray(data) ? data as Array<Record<string, unknown>> : [];
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
      const data = await this.getSectorsData<unknown>(`${this.baseUrl}/daily/${symbol}/`, { headers: this.headers });
      const rows = Array.isArray(data) ? data : [];
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
      return await this.fetchCompanyReport(symbol);
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 429) {
        console.warn(`Sectors rate limit reached for ${symbol}; returning empty report payload to prevent cascading failures.`);
      }
      return {};
    }
  }

  private async fetchCompanyReport(symbol: string): Promise<Record<string, unknown>> {
    const data = await this.getSectorsData<unknown>(`${this.baseUrl}/company/report/${symbol}/`, {
      headers: this.headers,
    });
    return data && typeof data === 'object' ? data as Record<string, unknown> : {};
  }

  private async getSectorsData<T>(url: string, options: AxiosRequestConfig = {}): Promise<T> {
    const params = options.params && typeof options.params === 'object'
      ? Object.fromEntries(
        Object.entries(options.params as Record<string, unknown>).sort(([left], [right]) => left.localeCompare(right)),
      )
      : options.params ?? null;
    const cacheKey = JSON.stringify([url, params]);
    const cached = this.responseCache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data as T;
    }
    if (cached) {
      this.responseCache.delete(cacheKey);
    }

    const pending = this.pendingRequests.get(cacheKey);
    if (pending) {
      return pending as Promise<T>;
    }

    const request = axios.get<T>(url, options)
      .then((response) => {
        if (this.responseCache.size >= 500) {
          const oldestKey = this.responseCache.keys().next().value;
          if (oldestKey) this.responseCache.delete(oldestKey);
        }
        this.responseCache.set(cacheKey, {
          data: response.data,
          expiresAt: Date.now() + this.getCacheTtl(url),
        });
        return response.data;
      })
      .finally(() => this.pendingRequests.delete(cacheKey));

    this.pendingRequests.set(cacheKey, request);
    return request;
  }

  private getCacheTtl(url: string): number {
    if (url.includes('/company/report/')) return 6 * 60 * 60 * 1000;
    if (url.includes('/daily/') || url.includes('/index-daily/') || url.includes('/most-traded/')) {
      return 5 * 60 * 1000;
    }
    return 60 * 60 * 1000;
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
    const data = await this.getSectorsData<Record<string, any>>(`${this.baseUrl}/most-traded/`, {
      headers: this.headers,
      params: { n_stock: 10 },
    });
    const dates = Object.keys(data ?? {}).sort();
    const latest = dates.at(-1);
    const rows = latest ? data[latest] : [];
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
        const data = await this.getSectorsData<unknown>(`${this.baseUrl}/mining/commodities/${name}/price/`, {
          headers: this.headers,
        });
        const rows = Array.isArray(data) ? data : [];
        const latest = rows.at(-1);
        return { name, price: latest?.price_usd_per_ton ?? null, date: latest?.date ?? null };
      } catch {
        return { name, price: null, date: null };
      }
    }));
  }

  private async getIndexSnapshot() {
    try {
      const data = await this.getSectorsData<unknown>(`${this.baseUrl}/index-daily/ihsg/`, {
        headers: this.headers,
      });
      const prices = Array.isArray(data) ? data : [];
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
