// src/config/influxdb.js
import { InfluxDB } from '@influxdata/influxdb-client';

let influx;
let writeApi;
let queryApi;

export function getInflux() {
  if (!influx) throw new Error('InfluxDB not initialized');
  return { influx, writeApi, queryApi };
}

export async function initInflux() {
  if (influx) return { influx, writeApi, queryApi };

  const url = process.env.INFLUX_URL || 'http://localhost:8086';
  const token = process.env.INFLUX_TOKEN || 'dev-token';
  const org = process.env.INFLUX_ORG || 'ghost-org';
  const bucket = process.env.INFLUX_BUCKET || 'ghost-cgm';

  influx = new InfluxDB({ url, token });
  writeApi = influx.getWriteApi(org, bucket);
  queryApi = influx.getQueryApi(org);

  console.log('InfluxDB client initialized');

  return { influx, writeApi, queryApi };
}
