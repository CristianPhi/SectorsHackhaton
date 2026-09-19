import { Controller, Get, Query } from '@nestjs/common';
import { AgentService } from './agent/agent.service';

@Controller('agent')
export class AppController {
  constructor(private readonly agentService: AgentService) {}

  @Get('analyze')
  async runAnalysis(@Query('prompt') prompt: string) {
    const result = await this.agentService.analyze(prompt || 'Analisa saham BBCA');
    
    console.log(result); 

    return {
      success: true,
      data: result,
    };
  }
}