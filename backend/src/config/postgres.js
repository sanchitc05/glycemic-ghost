// src/config/postgres.js
import pkg from 'pg';
const { Pool } = pkg;

let pool;

export function getPgPool() {
  if (!pool) throw new Error('Postgres pool not initialized');
  return pool;
}

export async function initPostgres() {
  if (pool) return pool;

  // here add the neondb string.
  pool = new Pool({
    connectionString: process.env.POSTGRES_URL || 'postgres://postgres:ghost@localhost:5432/ghost'
  });

  await pool.query('SELECT 1'); // simple connectivity check
  console.log('Postgres connected');

  return pool;
}
