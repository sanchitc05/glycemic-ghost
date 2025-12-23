// src/migrate.js
import fs from 'fs';
import path from 'path';
import url from 'url';
import dotenv from 'dotenv';
import { initPostgres, getPgPool } from './config/postgres.js';

dotenv.config();

const __filename = url.fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function ensureMigrationsTable(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS migrations (
      id SERIAL PRIMARY KEY,
      filename TEXT UNIQUE NOT NULL,
      executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

async function getExecutedMigrations(pool) {
  const { rows } = await pool.query('SELECT filename FROM migrations ORDER BY id ASC;');
  return new Set(rows.map((r) => r.filename));
}

async function runMigrations() {
  await initPostgres();
  const pool = getPgPool();

  await ensureMigrationsTable(pool);
  const executed = await getExecutedMigrations(pool);

  const migrationsDir = path.join(__dirname, 'migrations');
  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort(); // run in filename order

  for (const file of files) {
    if (executed.has(file)) {
      console.log(`Skipping already executed migration: ${file}`);
      continue;
    }

    const fullPath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(fullPath, 'utf8');

    console.log(`Running migration: ${file}`);
    try {
      await pool.query('BEGIN');
      await pool.query(sql);
      await pool.query('INSERT INTO migrations (filename) VALUES ($1);', [file]);
      await pool.query('COMMIT');
      console.log(`Migration succeeded: ${file}`);
    } catch (err) {
      await pool.query('ROLLBACK');
      console.error(`Migration failed: ${file}`, err);
      process.exit(1);
    }
  }

  console.log('All migrations up to date');
  await pool.end();
  process.exit(0);
}

runMigrations().catch((err) => {
  console.error('Migration runner error:', err);
  process.exit(1);
});
