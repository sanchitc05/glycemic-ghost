// src/routes/dexcom.routes.js
import { Router } from 'express';
import {
  getDexcomAuthUrl,
  handleDexcomCallback,
  getLatestEgvs,
} from '../services/dexcom.service.js';

const router = Router();

// GET /api/dexcom/connect?userId=123
router.get('/connect', async (req, res, next) => {
  try {
    const userId = req.query.userId;
    const url = getDexcomAuthUrl(userId);
    res.json({ url });
  } catch (err) {
    next(err);
  }
});

// GET /api/dexcom/callback
router.get('/callback', async (req, res, next) => {
  try {
    const { code, state } = req.query;
    await handleDexcomCallback({ code, state });
    res.send('Dexcom connected. You can close this window.');
  } catch (err) {
    next(err);
  }
});

// GET /api/dexcom/egvs?userId=123
router.get('/egvs', async (req, res, next) => {
  try {
    const userId = req.query.userId;
    const data = await getLatestEgvs(userId);
    res.json(data);
  } catch (err) {
    next(err);
  }
});

export default router;
