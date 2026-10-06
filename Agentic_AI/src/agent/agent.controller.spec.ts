import { AgentController } from './agent.controller';

describe('AgentController', () => {
  it('should return success payload from analyze', async () => {
    const service = {
      analyze: jest.fn().mockResolvedValue('Analisis selesai'),
    };

    const controller = new AgentController(service as any);
    const result = await controller.analyzeStock('BBCA');

    expect(result.status).toBe('success');
    expect(result.data).toBe('Analisis selesai');
  });

  it('forwards the requested ticker to the analysis service', async () => {
    const service = {
      analyze: jest.fn().mockResolvedValue({ ticker: 'AADI' }),
    };
    const controller = new AgentController(service as any);

    await controller.analyzeStock('Tolong analisis saham AADI', 'AADI');

    expect(service.analyze).toHaveBeenCalledWith(
      'Tolong analisis saham AADI',
      'AADI',
    );
  });
});
