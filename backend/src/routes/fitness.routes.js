import { Router } from 'express';
import * as fitnessService from '../services/fitness.service.js';
import { requireAuth } from '../middlewares/auth.middleware.js';

const router = Router();


// POST /api/fitness/metrics/bulk
router.post('/metrics/bulk', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { metrics } = req.body;

    if (!Array.isArray(metrics) || metrics.length === 0) {
      return res.status(400).json({ error: 'metrics array is required' });
    }

    await fitnessService.insertMetricsBulk(userId, metrics);

    res.status(201).json({ ok: true });
  } catch (err) {
    next(err);
  }
});


// GET /api/fitness/metrics?userId=123&type=steps&start=...&end=...
router.get('/metrics', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;                  // or use req.user.id
    const { type, start, end } = req.query;

    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    const metrics = await fitnessService.getMetrics({
      userId,
      type,
      start,
      end,
    });

    res.json({ metrics });
  } catch (err) {
    next(err);
  }
});

// POST /api/fitness/metrics  (for manual entries like BMI)
router.post('/metrics', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { metricType, value, unit, source, recordedAt, extra } =
      req.body;

    if (!metricType || value == null || !unit || !recordedAt) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const metric = await fitnessService.createMetric({
      userId,
      metricType,
      value,
      unit,
      source: source ?? 'manual',
      recordedAt,
      extra,
    });

    res.status(201).json({ metric });
  } catch (err) {
    next(err);
  }
});

export default router;
