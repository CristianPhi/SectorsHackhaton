import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { AxiosError } from 'axios';

@Injectable()
export class NewsService {
  private readonly logger = new Logger(NewsService.name);
  private readonly baseUrl: string;
  private readonly apiKey: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.baseUrl = this.configService.get<string>(
      'SECTORS_BASE_URL',
      'https://api.sectors.app/v2',
    );
    this.apiKey = this.configService.get<string>('SECTORS_API_KEY', '');
  }

  async getMarketNews(symbol?: string, page: number = 1): Promise<any> {
    if (!this.apiKey) {
      throw new HttpException(
        'API Key sectors.app belum disetel di environment variable',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    const endpoint = symbol
      ? `${this.baseUrl}/company/report/${symbol.toUpperCase()}/news/`
      : `${this.baseUrl}/news/`;

    try {
      const response = await firstValueFrom(
        this.httpService.get(endpoint, {
          headers: {
            Authorization: this.apiKey,
          },
          params: { limit: 20, offset: Math.max(0, (page - 1) * 20) },
          timeout: 10000,
        }),
      );
      return response.data;
    } catch (error) {
      const axiosError = error as AxiosError;
      const status =
        axiosError.response?.status || HttpStatus.INTERNAL_SERVER_ERROR;
      const message =
        axiosError.response?.data || axiosError.message || 'Gagal memanggil API sectors.app';

      this.logger.error(`Error fetching news: ${JSON.stringify(message)}`);
      throw new HttpException(message, status);
    }
  }
}