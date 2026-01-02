// src/config/postgres.js
import { Pool } from 'pg';

let pool;

export function initPostgres(config) {
  if (!pool) {
    pool = new Pool(config);
  }
  return pool;
}

export function getPgPool() {
  if (!pool) throw new Error('Postgres pool not initialized');
  return pool;
}
