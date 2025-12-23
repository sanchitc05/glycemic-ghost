// src/routes/index.js
import { Router } from 'express';
import dexcomRoutes from './dexcom.routes.js';

const router = Router();

// /api/dexcom
router.use('/dexcom', dexcomRoutes);

// temporary test routes
router.get('/cgm/test', (req, res) => {
  res.json({ message: 'CGM route stub' });
});

router.get('/fitness/test', (req, res) => {
  res.json({ message: 'Fitness route stub' });
});

router.get('/ai/test', (req, res) => {
  res.json({ message: 'AI route stub' });
});

export default router;
