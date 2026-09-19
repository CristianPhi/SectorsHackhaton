import { Injectable } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class SectorsService {
  private readonly baseUrl = 'https://api.sectors.app/v2';
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
}
