import { Controller, Post, Body } from '@nestjs/common';
import { AgentService } from './agent.service';

@Controller('agent')
export class AgentController {
  constructor(private readonly agentService: AgentService) {}

  @Post('analyze')
  async analyzeStock(@Body('prompt') prompt: string) {
    const result = await this.agentService.analyze(prompt);
    return { status: 'success', data: result};
  }
}
