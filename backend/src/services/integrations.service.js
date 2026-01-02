// src/services/integrations.service.js - COMPLETE FIXED FILE
import { getPgPool } from '../config/postgres.js';
import axios from 'axios';

export async function checkIntegrationStatus(userId) {
  const pool = getPgPool();
  // ✅ FIXED: PostgreSQL syntax (no JavaScript Date)
  const { rows } = await pool.query(
    `SELECT provider, expires_at 
     FROM integrations 
     WHERE user_id = $1 AND expires_at > NOW()`,
    [userId]
  );
  
  const connected = rows.map(row => row.provider);
  
  return {
    connected,
    needsConnect: !connected.includes('dexcom'),
    pendingProviders: ['dexcom']
  };
}

export async function getValidAccessToken(userId, provider = 'dexcom') {
  const pool = getPgPool();
  const { rows } = await pool.query(
    'SELECT access_token, refresh_token, expires_at FROM integrations WHERE user_id = $1 AND provider = $2',
    [userId, provider]
  );
  
  if (!rows.length) {
    console.log(`⚠️ No ${provider} tokens → Demo mode`);
    return 'DEMO_TOKEN';  // ✅ Demo fallback!
  }
  
  const token = rows[0];
  if (new Date(token.expires_at) > new Date()) {
    return token.access_token;
  }
  
  throw new Error(`${provider} token expired (refresh not implemented)`);
}

export async function saveProviderTokens(userId, provider, tokens) {
  const pool = getPgPool();
  await pool.query(
    `INSERT INTO integrations (user_id, provider, access_token, refresh_token, expires_at)
     VALUES ($1, $2, $3, $4, NOW() + ($5 || ' seconds')::interval)
     ON CONFLICT (user_id, provider) DO UPDATE SET
       access_token = EXCLUDED.access_token,
       refresh_token = EXCLUDED.refresh_token,
       expires_at = EXCLUDED.expires_at,
       updated_at = NOW()`,
    [userId, provider, tokens.access_token, tokens.refresh_token, tokens.expires_in]
  );
}
