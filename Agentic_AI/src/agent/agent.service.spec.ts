import { AgentService } from './agent.service';

describe('AgentService', () => {
  it('should be defined', () => {
    const service = new AgentService(
      {
        screenCompanies: jest.fn(),
        getCompanyOverview: jest.fn(),
        getTechnicalIndicators: jest.fn(),
      } as any,
      {
        getBrokerSummary: jest.fn().mockResolvedValue([]),
      } as any,
    );

    expect(service).toBeDefined();
  });

  it('maps real nested broker summary payloads into broker news entries', async () => {
    process.env.GEMINI_API_KEY = '';
    const service = new AgentService(
      {
        screenCompanies: jest.fn(),
        getCompanyOverview: jest.fn(),
        getTechnicalIndicators: jest.fn(),
        getStockDetail: jest.fn().mockResolvedValue({
          teknikal: [],
          fundamental: [],
          berita: [],
        }),
      } as any,
      {
        getBrokerSummary: jest.fn().mockResolvedValue({
          symbol: 'BBCA.JK',
          data: [
            {
              date: '2026-09-24',
              summary: [
                { broker_code: 'AF', nlot: 50, nval: 32125000 },
                { broker_code: 'BC', nlot: -30, nval: -18600000 },
              ],
            },
          ],
        }),
      } as any,
    );

    const result = await service.analyze('Analisis BBCA');

    expect(result.berita[0].source).toBe('AF');
    expect(result.berita[0].title).toContain('AF');
    expect(result.berita[1].source).toBe('BC');
  });

  it('uses an explicitly requested ticker and removes technical N/A placeholders', async () => {
    process.env.GEMINI_API_KEY = '';
    const getStockDetail = jest.fn().mockResolvedValue({
      stock: { ticker: 'AADI', price: 6100, changePercent: -1.21 },
      dayHigh: 6350,
      dayLow: 6000,
      sparkline: [6000, 6350, 6100],
      teknikal: [
        {
          name: 'RSI',
          value: 'N/A',
          interpretation: 'N/A',
          signal: 'netral',
        },
      ],
      fundamental: [],
      berita: [],
    });
    const service = new AgentService(
      { getStockDetail } as any,
      { getBrokerSummary: jest.fn().mockResolvedValue([]) } as any,
    );

    const result = await service.analyze('Tolong analisis saham AADI', 'AADI');

    expect(getStockDetail).toHaveBeenCalledWith('AADI');
    expect(result.ticker).toBe('AADI');
    expect(result.title).toBe('Analisis AADI');
    expect(result.teknikal[0].value).toBe('Data belum tersedia');
    expect(result.teknikal.some((row: any) => row.value === 'N/A')).toBe(false);
  });
});
