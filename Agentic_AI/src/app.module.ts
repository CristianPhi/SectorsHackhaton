import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'; // 1. Import ConfigModule
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SectorsService } from './sectors/sectors.service';
import { AgentService } from './agent/agent.service';
import { AgentController } from './agent/agent.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }), // 2. Tambahkan di sini
  ],
  controllers: [AppController, AgentController],
  providers: [AppService, SectorsService, AgentService],
})
export class AppModule {}