import { AppController } from './app.controller';

describe('AppController', () => {
  it('should return health status', () => {
    const appController = new AppController();
    const result = appController.getHealth();

    expect(result.status).toBe('ok');
    expect(result.service).toBe('Agentic_AI');
  });
});
