import { Controller, Post, Body } from '@nestjs/common';
import { AgentService } from './agent.service.js';

@Controller('agent')
export class AgentController {
  constructor(private readonly agentService: AgentService) {}

  @Post('analyze')
  async analyzeStock(
    @Body('prompt') prompt: string,
    @Body('ticker') ticker?: string,
  ) {
    const result = await this.agentService.analyze(prompt, ticker);
    return { status: 'success', data: result };
  }
}
