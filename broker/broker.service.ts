import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class BrokerService {
  private readonly baseUrl = 'https://api.sectors.app/v2';
  private readonly headers = {
    Authorization: process.env.SECTORS_API_KEY,
  };

  private async request<T>(path: string, params: Record<string, unknown> = {}): Promise<T> {
    if (!process.env.SECTORS_API_KEY) {
      throw new ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
    }

    const response = await axios.get(`${this.baseUrl}${path}`, {
      headers: this.headers,
      params,
    });

    return response.data as T;
  }

  async getBrokers() {
    return this.request<any[]>('/brokers/');
  }

  async getTopBrokers() {
    return this.request<any>('/brokers/top/');
  }

  async getBrokerActivity(brokerCode: string) {
    const cleanCode = brokerCode.trim().toUpperCase();
    return this.request<any>(`/broker-activity/${cleanCode}/`);
  }

  async getBrokerActivityTop(brokerCode: string) {
    const cleanCode = brokerCode.trim().toUpperCase();
    return this.request<any>(`/broker-activity/${cleanCode}/top/`);
  }

  async getBrokerSummary(symbol: string) {
    const cleanSymbol = symbol.trim().toUpperCase().replace(/\.JK$/i, '');
    return this.request<any>(`/broker-summary/${cleanSymbol}/`);
  }

  async getBrokerSummaryTop(symbol: string) {
    const cleanSymbol = symbol.trim().toUpperCase().replace(/\.JK$/i, '');
    return this.request<any>(`/broker-summary/${cleanSymbol}/top/`);
  }

  async getForeignFlow() {
    return this.request<any>('/foreign-flow/', {
      order_by: '-net_foreign_inflow',
      limit: 20,
    });
  }

  async getForeignFlowBySymbol(symbol: string) {
    const cleanSymbol = symbol.trim().toUpperCase().replace(/\.JK$/i, '');
    return this.request<any>(`/foreign-flow/${cleanSymbol}/`);
  }
}
