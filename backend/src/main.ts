import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Global validation: strips unknown properties, rejects malformed payloads,
  // and converts primitive types coming from JSON automatically.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (errors) => {
        const messages = errors.map((err) =>
          Object.values(err.constraints || {}).join(', '),
        );
        return {
          statusCode: 400,
          error: 'Bad Request',
          message: messages,
        };
      },
    }),
  );

  // Allow the Flutter app (emulator/device) to call the API during local dev.
  app.enableCors();

  const port = process.env.PORT || 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`Task API listening on http://localhost:${port}`);
}
bootstrap();
