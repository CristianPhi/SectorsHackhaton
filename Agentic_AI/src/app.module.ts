import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { SectorsService } from './sectors/sectors.service.js';
import { AgentService } from './agent/agent.service.js';
import { AgentController } from './agent/agent.controller.js';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from './auth/auth.module.js';
import { SectorsController } from './sectors/sectors.controller.js';
import { BrokerController } from '../../broker/broker.controller.js';
import { BrokerService } from '../../broker/broker.service.js';
import { ApiNewsController, LearnController } from './learn/learn.controller.js';
import { LearnService } from './learn/learn.service.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const configuredUri = (configService.get<string>('MONGODB_URI') ?? '').trim();
         const unquotedValue = configuredUri.replace(/^("|')(.*)\1$/, '$2').trim();
         const withoutKey = unquotedValue.replace(/^MONGODB_URI\s*=\s*/i, '').trim();
         const uri = withoutKey.replace(/^("|')(.*)\1$/, '$2').trim();
        if (!/^mongodb(?:\+srv)?:\/\//i.test(uri)) {
          throw new Error('MONGODB_URI harus diawali mongodb:// atau mongodb+srv://');
        }
        return { uri };
      },
    }),
    AuthModule,
  ],
  controllers: [AppController, AgentController, SectorsController, BrokerController, LearnController, ApiNewsController],
  providers: [AppService, SectorsService, BrokerService, AgentService, LearnService],
})
export class AppModule {}