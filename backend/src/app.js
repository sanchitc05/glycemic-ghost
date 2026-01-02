// src/app.js
import express from 'express';
import {} from 'dotenv/config';
import morgan from 'morgan';

import { initPostgres } from './config/postgres.js';
import { initInflux } from './config/influxdb.js';
import { initRedis } from './config/redis.js';

import router from './routes/index.js';


  export async function createApp() {

    const dbConfig = {
      connectionString: process.env.POSTGRES_URL,
      // user: process.env.DB_USER,
      // host: process.env.DB_HOST,
      // database: process.env.DB_NAME,
      // password: process.env.DB_PASSWORD,
      // port: process.env.DB_PORT,
    };

  // init external services
  await initPostgres(dbConfig);
  await initInflux();
  await initRedis();

  const app = express();

  app.use(express.json());
  app.use(morgan('dev'));

  app.use('/api', router);

  app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'glycemic-ghost-backend' });
  });

  return app;
}
