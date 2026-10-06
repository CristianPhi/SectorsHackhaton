import { ValidationPipe, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { AppModule } from '../Agentic_AI/src/app.module';

let appPromise: Promise<INestApplication> | undefined;

async function createApp(): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.enableCors({ origin: true, credentials: true });
  await app.init();
  return app;
}

export default async function handler(
  request: IncomingMessage,
  response: ServerResponse,
): Promise<void> {
  appPromise ??= createApp();
  try {
    const app = await appPromise;
    const expressHandler = app.getHttpAdapter().getInstance() as unknown as (
      request: IncomingMessage,
      response: ServerResponse,
    ) => void;
    expressHandler(request, response);
  } catch (error) {
    appPromise = undefined;
    throw error;
  }
}

export const config = {
  api: { bodyParser: false },
};