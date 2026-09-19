import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import axios from 'axios';

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

    const [companies, mostTraded, commodities] = await Promise.all([
      this.getCompanies(query),
      this.getMostTraded(),
      this.getCommodityPrices(),
    ]);

    return { companies, mostTraded, commodities, source: 'Sectors Financial API' };
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
