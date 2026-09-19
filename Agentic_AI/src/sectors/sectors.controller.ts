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
  search(@Query('q') query?: string) {
    return this.sectorsService.getSearchData(query ?? '');
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
