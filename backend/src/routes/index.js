// src/routes/index.js
import { Router } from 'express';
import dexcomRoutes from './dexcom.routes.js';
import fitnessRoutes from './fitness.routes.js';
import authRoutes from './auth.routes.js';
import foodRoutes from './food.routes.js';
import emergencyRoutes from './emergency.routes.js';

const router = Router();

// /api/dexcom
router.use('/dexcom', dexcomRoutes);

// temporary test routes
router.use('/cgm/test', fitnessRoutes);

router.use('/auth', authRoutes)
router.use('/fitness', fitnessRoutes);
router.use('/food', foodRoutes);
router.use('/emergency', emergencyRoutes);

router.get('/ai/test', (req, res) => {
  res.json({ message: 'AI route stub' });
});

export default router;
