// src/config/redis.js
import Redis from 'ioredis';

let redis;

export function getRedis() {
  if (!redis) throw new Error('Redis not initialized');
  return redis;
}

export async function initRedis() {
  if (redis) return redis;

  const url = process.env.REDIS_URL || 'redis://localhost:6379';
  redis = new Redis(url);

  redis.on('error', (err) => {
    console.error('Redis error', err);
  });

  await redis.ping(); // connectivity check
  console.log('Redis connected');

  return redis;
}
