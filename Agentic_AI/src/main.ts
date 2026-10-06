import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.enableCors({
    origin: true,
    credentials: true,
  });

  const preferredPort = Number(process.env.PORT ?? 3002);
  let currentPort = preferredPort;

  while (currentPort < preferredPort + 20) {
    try {
      await app.listen(currentPort, '0.0.0.0');
      console.log(`Application is running on: http://localhost:${currentPort}`);
      return;
    } catch (error) {
      const err = error as NodeJS.ErrnoException;
      if (err.code === 'EADDRINUSE') {
        console.warn(`Port ${currentPort} is already in use. Retrying on port ${currentPort + 1}...`);
        currentPort += 1;
        continue;
      }
      throw error;
    }
  }

  throw new Error(`Could not start the application between ports ${preferredPort} and ${currentPort}.`);
}

bootstrap();
