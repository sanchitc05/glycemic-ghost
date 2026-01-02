// src/services/fitness.service.js
import { getPgPool } from '../config/postgres.js';



export async function getMetrics({ userId, type, start, end }) {
  const pool = getPgPool();
  const params = [userId];
  const where = ['user_id = $1'];

  if (type) {
    params.push(type);
    where.push(`metric_type = $${params.length}`);
  }

  if (start) {
    params.push(start);
    where.push(`recorded_at >= $${params.length}`);
  }

  if (end) {
    params.push(end);
    where.push(`recorded_at <= $${params.length}`);
  }

  const query = `
    SELECT id, metric_type, value, unit, source, extra, recorded_at
    FROM fitness_metrics
    WHERE ${where.join(' AND ')}
    ORDER BY recorded_at DESC
    LIMIT 1000
  `;

  const { rows } = await pool.query(query, params);
  return rows;
}

export async function createMetric({
  userId,
  metricType,
  value,
  unit,
  source,
  recordedAt,
  extra,
}) {
  const query = `
    INSERT INTO fitness_metrics
      (user_id, metric_type, value, unit, source, recorded_at, extra)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id, metric_type, value, unit, source, extra, recorded_at
  `;

  const params = [
    userId,
    metricType,
    value,
    unit,
    source,
    recordedAt,
    extra ?? null,
  ];

  const { rows } = await pool.query(query, params);
  return rows[0];
}


export async function insertMetricsBulk(userId, metrics) {
  const pool = getPgPool();
  const values = [];
  const params = [];

  metrics.forEach((m, i) => {
    const idx = i * 7;
    params.push(
      userId,
      m.metricType,
      m.value,
      m.unit,
      m.source || 'health_connect',
      m.recordedAt,
      m.extra || null
    );
    values.push(
      `($${idx + 1}, $${idx + 2}, $${idx + 3}, $${idx + 4}, $${idx + 5}, $${idx + 6}, $${idx + 7})`
    );
  });

  const query = `
    INSERT INTO fitness_metrics
      (user_id, metric_type, value, unit, source, recorded_at, extra)
    VALUES ${values.join(',')}
  `;

  await pool.query(query, params);
}
