import { Controller, Get, Param, Query } from '@nestjs/common';
import { SectorsService } from './sectors.service';

@Controller('sectors')
export class SectorsController {
  constructor(private readonly sectorsService: SectorsService) {}

  @Get('market')
  getMarketSnapshot() {
    return this.sectorsService.getMarketSnapshot();
  }

  @Get('search')
  search(
    @Query('q') query?: string,
    @Query('maxPe') maxPe?: string,
    @Query('maxPbv') maxPbv?: string,
    @Query('minTransaction') minTransaction?: string,
    @Query('sortBy') sortBy?: 'transaction' | 'valuation' | 'price',
  ) {
    return this.sectorsService.getScreenerData({
      q: query ?? '',
      maxPe: maxPe ? Number(maxPe) : undefined,
      maxPbv: maxPbv ? Number(maxPbv) : undefined,
      minTransaction: minTransaction ? Number(minTransaction) : undefined,
      sortBy,
    });
  }

  @Get('screener')
  screener(
    @Query('q') q?: string,
    @Query('maxPe') maxPe?: string,
    @Query('maxPbv') maxPbv?: string,
    @Query('minPe') minPe?: string,
    @Query('minPbv') minPbv?: string,
    @Query('minTransaction') minTransaction?: string,
    @Query('minRoe') minRoe?: string,
    @Query('maxRoe') maxRoe?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
    @Query('sortBy') sortBy?: 'transaction' | 'valuation' | 'price',
  ) {
    return this.sectorsService.getScreenerData({
      q: q ?? '',
      maxPe: maxPe ? Number(maxPe) : undefined,
      maxPbv: maxPbv ? Number(maxPbv) : undefined,
      minPe: minPe ? Number(minPe) : undefined,
      minPbv: minPbv ? Number(minPbv) : undefined,
      minTransaction: minTransaction ? Number(minTransaction) : undefined,
      minRoe: minRoe ? Number(minRoe) : undefined,
      maxRoe: maxRoe ? Number(maxRoe) : undefined,
      minPrice: minPrice ? Number(minPrice) : undefined,
      maxPrice: maxPrice ? Number(maxPrice) : undefined,
      sortBy,
    });
  }

  @Get('trending')
  trending(@Query('limit') limit?: string) {
    return this.sectorsService.getTrendingStocks({
      limit: limit ? Number(limit) : 10,
      minTransaction: 0,
    });
  }

  @Get('stocks/:symbol/transactions')
  getStockTransactions(@Param('symbol') symbol: string) {
    return this.sectorsService.getStockTransactions(symbol);
  }

  @Get('stocks/:symbol')
  getStockDetail(@Param('symbol') symbol: string) {
    return this.sectorsService.getStockDetail(symbol);
  }

  @Get('stocks/:symbol/quote')
  getStockQuote(@Param('symbol') symbol: string) {
    return this.sectorsService.getStockQuote(symbol);
  }
}
