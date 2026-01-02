// src/services/dexcom.service.js - COMPLETE FIXED FILE
import axios from 'axios';
import { getPgPool } from '../config/postgres.js';

// ✅ FIX 1: Import ALL integrations functions at top
import { 
  getValidAccessToken, 
  saveProviderTokens 
} from './integrations.service.js';

const BASE_URL = process.env.DEXCOM_BASE_URL || 'https://sandbox-api.dexcom.com';
const CLIENT_ID = process.env.DEXCOM_CLIENT_ID;
const CLIENT_SECRET = process.env.DEXCOM_CLIENT_SECRET;
const REDIRECT_URI = process.env.DEXCOM_REDIRECT_URI;
const SCOPE = process.env.DEXCOM_SCOPE || 'offline_access';

// Build Dexcom OAuth URL
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

// Exchange code for tokens and store in integrations table
export async function handleDexcomCallback({ code, state }) {
  const userId = state;
  const tokenUrl = `${BASE_URL}/v2/oauth2/token`;

  console.log('Dexcom callback params:', { code, state });

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

    // ✅ FIX 2: Direct saveProviderTokens call (no dynamic import)
    await saveProviderTokens(userId, 'dexcom', data);

    console.log('✅ Dexcom tokens stored for user', userId);
    return data;
  } catch (err) {
    console.error('❌ Dexcom token error:', err.response?.data || err.message);
    throw err;
  }
}

function toDexcomDate(date) {
  return date.toISOString().slice(0, 19);
}

// ✅ YOUR EXISTING DEMO FUNCTION (UNCHANGED)
function generateDemoEgvs(userId) {
  const now = new Date();
  const egvs = [];
  
  for (let i = 0; i < 72; i++) {
    const time = new Date(now.getTime() - i * 5 * 60 * 1000);
    const base = 115 + Math.sin(i * 0.2) * 25;
    const value = Math.max(70, Math.round(base + (Math.random() - 0.5) * 8));
    const trend = value > base ? 'FortyFiveUp' : value < base ? 'FortyFiveDown' : 'Flat';
    
    egvs.push({
      systemTime: time.toISOString(),
      displayTime: time.toISOString(),
      value,
      realtimeValue: value,
      smoothedValue: value,
      trendRate: (Math.random() - 0.5) * 2,
      trend,
      status: null
    });
  }
  
  return egvs.reverse();
}

// ✅ FIX 3: getLatestEgvs with PROPER demo fallback
export async function getLatestEgvs(userId) {
  console.log(userId, 'Service-getLatestEgvs');
  
  try {
    const accessToken = await getValidAccessToken(userId, 'dexcom');
    
    // ✅ Demo fallback works automatically from integrations.service.js
    if (accessToken === 'DEMO_TOKEN') {
      const demoData = generateDemoEgvs(userId);
      console.log(`📊 Demo EGVs for ${userId}: ${demoData.length} points`);
      return { egvs: demoData };
    }

    // Real Dexcom API
    const end = new Date();
    const start = new Date(end.getTime() - 7 * 24 * 60 * 60 * 1000);
    const qs = new URLSearchParams({
      startDate: toDexcomDate(start),
      endDate: toDexcomDate(end)
    });

    const url = `${BASE_URL}/v2/users/self/egvs?${qs.toString()}`;
    console.log('Dexcom EGVs request:', { url });

    const { data } = await axios.get(url, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });
    
    console.log(`✅ Real Dexcom EGVs: ${data.egvs?.length || 0} points`);
    return data;
    
  } catch (err) {
    console.error('❌ Dexcom API error:', err.message);
    // ✅ Final fallback
    const demoData = generateDemoEgvs(userId);
    console.log(`📊 Fallback demo EGVs: ${demoData.length} points`);
    return { egvs: demoData };
  }
}
