import "dotenv/config";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  const port = Number(process.env.PORT || 3001);
  await app.listen(port);
  console.log(
    `Detailed Reports service is running on: http://localhost:${port}`,
  );
}
bootstrap();
