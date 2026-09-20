import { Test, TestingModule } from '@nestjs/testing';
import { SectorsService } from './sectors.service';

describe('SectorsService', () => {
  let service: SectorsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SectorsService],
    }).compile();

    service = module.get<SectorsService>(SectorsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should mark cheap valuation when pe and pbv are below thresholds', () => {
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
    const sorted = service.sortStocksByTransaction([
      { symbol: 'A', transactionCount: 5000 },
      { symbol: 'B', transactionCount: 20000 },
      { symbol: 'C', transactionCount: 12000 },
    ]);

    expect(sorted[0].symbol).toBe('B');
    expect(sorted[1].symbol).toBe('C');
    expect(sorted[2].symbol).toBe('A');
  });
});
