import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SectorsService } from './sectors/sectors.service';
import { AgentService } from './agent/agent.service';
import { AgentController } from './agent/agent.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from './auth/auth.module';
import { SectorsController } from './sectors/sectors.controller';
import { BrokerController } from '@broker/broker.controller';
import { BrokerService } from '@broker/broker.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const configuredUri = configService.getOrThrow<string>('MONGODB_URI').trim();
        const uri = configuredUri.replace(/^MONGODB_URI=/, '');
        return { uri };
      },
    }),
    AuthModule,
  ],
  controllers: [AppController, AgentController, SectorsController, BrokerController],
  providers: [AppService, SectorsService, BrokerService, AgentService],
})
export class AppModule {}