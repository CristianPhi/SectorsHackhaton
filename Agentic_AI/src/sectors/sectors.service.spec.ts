import { SectorsService } from './sectors.service';
import axios from 'axios';

describe('SectorsService', () => {
  afterEach(() => jest.restoreAllMocks());

  it('should be defined', () => {
    const service = new SectorsService();
    expect(service).toBeDefined();
  });

  it('should mark cheap valuation when pe and pbv are below thresholds', () => {
    const service = new SectorsService();
    const metrics = service.calculateValuationMetrics({
      price: 100,
      eps: 8,
      bookValue: 60,
    });

    expect(metrics.peRatio).toBe(12.5);
    expect(metrics.pbv).toBe(1.6666666666666667);
    expect(metrics.isCheap).toBe(true);
  });

  it('should sort trending stocks by highest transaction count first', () => {
    const service = new SectorsService();
    const sorted = service.sortStocksByTransaction([
      { symbol: 'A', transactionCount: 5000 },
      { symbol: 'B', transactionCount: 20000 },
      { symbol: 'C', transactionCount: 12000 },
    ]);

    expect(sorted[0].symbol).toBe('B');
    expect(sorted[1].symbol).toBe('C');
    expect(sorted[2].symbol).toBe('A');
  });

  it('should reuse a cached company report for the same normalized ticker', async () => {
    const service = new SectorsService();
    const report = { symbol: 'BBCA', pe: 12 };
    const getSpy = jest.spyOn(axios, 'get').mockResolvedValue({ data: report } as never);

    const firstResponse = await service.getCompanyOverview('bbca');
    const secondResponse = await service.getCompanyOverview('BBCA.JK');

    expect(firstResponse).toBe(JSON.stringify(report));
    expect(secondResponse).toBe(firstResponse);
    expect(getSpy).toHaveBeenCalledTimes(1);
  });

  it('should share one daily quote request for concurrent normalized tickers', async () => {
    const service = new SectorsService();
    const getSpy = jest.spyOn(axios, 'get').mockResolvedValue({
      data: [{ close: 100 }, { close: 110 }],
    } as never);

    const quotes = await Promise.all([
      service.getStockQuote('bbca'),
      service.getStockQuote('BBCA.JK'),
    ]);

    expect(quotes[0]).toEqual(quotes[1]);
    expect(getSpy).toHaveBeenCalledTimes(1);
  });
});
