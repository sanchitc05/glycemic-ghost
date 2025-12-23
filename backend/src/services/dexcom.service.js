// src/services/dexcom.service.js
import axios from 'axios';
import { getPgPool } from '../config/postgres.js';

const BASE_URL = process.env.DEXCOM_BASE_URL || 'https://sandbox-api.dexcom.com';
const CLIENT_ID = process.env.DEXCOM_CLIENT_ID;
const CLIENT_SECRET = process.env.DEXCOM_CLIENT_SECRET;
const REDIRECT_URI = process.env.DEXCOM_REDIRECT_URI;
const SCOPE = process.env.DEXCOM_SCOPE || 'offline_access';

// build Dexcom OAuth URL
export function getDexcomAuthUrl(userId) {
    console.log(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI, "Backend");
  const params = new URLSearchParams({
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    response_type: 'code',
    scope: SCOPE,
    state: String(userId || '')
  });
  return `${BASE_URL}/v2/oauth2/login?${params.toString()}`;
}
// src/services/dexcom.service.js

// exchange code for tokens and store
export async function handleDexcomCallback({ code, state }) {
  const userId = state; // later replace with your real user auth mapping
  const tokenUrl = `${BASE_URL}/v2/oauth2/token`;
    
  // TEMP: hard-coded sandbox client values (for debugging only)
//   const CLIENT_ID = CLIENT_ID
//   const CLIENT_SECRET = CLIENT_SECRET
//   const REDIRECT_URI = REDIRECT_URI

  console.log('Dexcom callback params:', { code, state });
  console.log('Dexcom token request debug:', {
    tokenUrl,
    BASE_URL,
    CLIENT_ID,
    hasSecret: !!CLIENT_SECRET,
    REDIRECT_URI
  });

  const body = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    code,
    grant_type: 'authorization_code',
    redirect_uri: REDIRECT_URI
  });

  try {
    const { data } = await axios.post(tokenUrl, body.toString(), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });

    const { access_token, refresh_token, expires_in } = data;

    const pool = getPgPool();
    await pool.query(
      `
      INSERT INTO dexcom_tokens (user_id, access_token, refresh_token, expires_at)
      VALUES ($1, $2, $3, NOW() + ($4 || ' seconds')::interval)
      ON CONFLICT (user_id)
      DO UPDATE SET access_token = EXCLUDED.access_token,
                    refresh_token = EXCLUDED.refresh_token,
                    expires_at   = EXCLUDED.expires_at
      `,
      [userId, access_token, refresh_token, expires_in]
    );

    console.log('Dexcom tokens stored for user', userId);
    return data;
  } catch (err) {
    console.error('Dexcom token error status:', err.response?.status);
    console.error('Dexcom token error data:', err.response?.data);
    throw err;
  }
}

// helper: get valid access token (refresh if expired)
async function getValidAccessToken(userId) {
  const pool = getPgPool();
  const { rows } = await pool.query(
    'SELECT access_token, refresh_token, expires_at FROM dexcom_tokens WHERE user_id = $1',
    [userId]
  );
  if (!rows.length) throw new Error('Dexcom not connected');

  const token = rows[0];
  console.log(token, "service-getvalidAccessTOken");
  
  if (new Date(token.expires_at) > new Date()) {
    console.log("Date is not matching whatever");
    
    return token.access_token;
  }

  // refresh
  const tokenUrl = `${BASE_URL}/v2/oauth2/token`;
  const body = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: token.refresh_token,
    grant_type: 'refresh_token',
    redirect_uri: REDIRECT_URI
  });
  
  console.log(body);
  
  const { data } = await axios.post(tokenUrl, body.toString(), {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
  });

  console.log(data);

  const { access_token, refresh_token, expires_in } = data;

  await pool.query(
    `
    UPDATE dexcom_tokens
    SET access_token = $2,
        refresh_token = $3,
        expires_at = NOW() + ($4 || ' seconds')::interval
    WHERE user_id = $1
    `,
    [userId, access_token, refresh_token, expires_in]
  );

  return access_token;
}

// fetch latest EGVS (CGM readings)
export async function getLatestEgvs(userId) {
  console.log(userId, "Service-getLatestEgvs");
  const accessToken = await getValidAccessToken(userId);

  // For now: last 3 hours
  const end = new Date();
  const start = new Date(end.getTime() - 3 * 60 * 60 * 1000);

  const qs = new URLSearchParams({
    startDate: start.toISOString(),
    endDate: end.toISOString()
  });

  const url = `${BASE_URL}/v2/users/self/egvs?${qs.toString()}`; // or /v3 for newer API[web:127][web:132]

  const { data } = await axios.get(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  return data; // later, pipe this into InfluxDB
}
