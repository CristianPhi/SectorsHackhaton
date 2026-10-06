import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      service: 'Agentic_AI',
      timestamp: new Date().toISOString(),
    };
  }
}