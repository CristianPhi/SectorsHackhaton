import { Controller, Get, Param, Query } from '@nestjs/common';
import { BrokerService } from './broker.service';

@Controller('broker')
export class BrokerController {
  constructor(private readonly brokerService: BrokerService) {}

  @Get('brokers')
  getBrokers() {
    return this.brokerService.getBrokers();
  }

  @Get('brokers/top')
  getTopBrokers() {
    return this.brokerService.getTopBrokers();
  }

  @Get('activity/:brokerCode')
  getBrokerActivity(@Param('brokerCode') brokerCode: string) {
    return this.brokerService.getBrokerActivity(brokerCode);
  }

  @Get('activity/:brokerCode/top')
  getBrokerActivityTop(@Param('brokerCode') brokerCode: string) {
    return this.brokerService.getBrokerActivityTop(brokerCode);
  }

  @Get('summary/:symbol')
  getBrokerSummary(@Param('symbol') symbol: string) {
    return this.brokerService.getBrokerSummary(symbol);
  }

  @Get('summary/:symbol/top')
  getBrokerSummaryTop(@Param('symbol') symbol: string) {
    return this.brokerService.getBrokerSummaryTop(symbol);
  }

  @Get('foreign-flow')
  getForeignFlow(@Query('limit') limit?: string) {
    const parsedLimit = limit ? Number(limit) : 20;
    return this.brokerService.getForeignFlow();
  }

  @Get('foreign-flow/:symbol')
  getForeignFlowBySymbol(@Param('symbol') symbol: string) {
    return this.brokerService.getForeignFlowBySymbol(symbol);
  }
}
