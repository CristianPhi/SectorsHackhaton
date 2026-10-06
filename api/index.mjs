import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../Agentic_AI/dist/Agentic_AI/src/app.module.js';

let appPromise;

async function createApp() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.enableCors({ origin: true, credentials: true });
  await app.init();
  return app;
}

async function getApp() {
  if (!appPromise) {
    appPromise = createApp().catch((error) => {
      appPromise = undefined;
      throw error;
    });
  }
  return appPromise;
}

export default async function handler(request, response) {
  const app = await getApp();
  const expressHandler = app.getHttpAdapter().getInstance();
  expressHandler(request, response);
}

export const config = {
  api: { bodyParser: false },
};