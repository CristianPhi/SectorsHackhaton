import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  InternalServerErrorException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { HttpService } from "@nestjs/axios";
import { AxiosError } from "axios";
import { firstValueFrom } from "rxjs";

@Injectable()
export class DetailedReportsService {
  private readonly baseUrl: string;
  private readonly apiKey: string;

  constructor(private readonly httpService: HttpService) {
    this.baseUrl = (
      process.env.SECTORS_BASE_URL || "https://api.sectors.app/v2"
    ).replace(/\/$/, "");
    this.apiKey = (process.env.SECTORS_API_KEY || "").trim();

    if (!this.apiKey) {
      throw new InternalServerErrorException(
        "SECTORS_API_KEY is not configured",
      );
    }
  }

  async getCompanyReport(symbol: string, sections?: string): Promise<unknown> {
    return this.fetchData(`/company/report/${this.symbolPath(symbol)}/`, {
      sections,
    });
  }

  async getShareholders(symbol: string, year?: number): Promise<unknown> {
    return this.fetchData(
      `/company/shareholders-composition/${this.symbolPath(symbol)}/`,
      {
        year,
      },
    );
  }

  async getQuarterlyFinancials(
    symbol: string,
    query: { report_date?: string; approx?: boolean; n_quarters?: number },
  ): Promise<unknown> {
    return this.fetchData(
      `/financials/quarterly/${this.symbolPath(symbol)}/`,
      query,
    );
  }

  private symbolPath(symbol: string): string {
    const normalizedSymbol = symbol.trim().toUpperCase();

    if (!/^[A-Z]{4}(?:\.JK)?$/.test(normalizedSymbol)) {
      throw new BadRequestException(
        "symbol must be four letters, optionally followed by .JK",
      );
    }

    return encodeURIComponent(normalizedSymbol);
  }

  private async fetchData(
    path: string,
    params: Record<string, string | number | boolean | undefined> = {},
  ): Promise<unknown> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}${path}`, {
          headers: { Authorization: this.apiKey },
          params,
          timeout: 15_000,
        }),
      );
      return response.data;
    } catch (error: unknown) {
      const axiosError = error as AxiosError;
      const status = axiosError.response?.status;
      const data = axiosError.response?.data;

      if (status && status >= 400 && status < 500) {
        throw new HttpException(data || "Sectors API request failed", status);
      }

      throw new ServiceUnavailableException(
        "Sectors API is unavailable. Please try again later.",
      );
    }
  }
}
