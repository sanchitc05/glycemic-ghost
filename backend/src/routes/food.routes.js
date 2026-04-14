import { Router } from 'express';
import * as foodService from '../services/food.service.js';
import { requireAuth } from '../middlewares/auth.middleware.js';

const router = Router();

// ✅ GET /api/food/search?q=chapati
router.get('/search', requireAuth, async (req, res, next) => {
  try {
    const { q } = req.query;
    const foods = await foodService.searchFoods(q || '');
    res.json({ foods });
  } catch (err) {
    next(err);
  }
});

// ✅ GET /api/food/recommendations?limit=20
router.get('/recommendations', requireAuth, async (req, res, next) => {
  try {
    const { limit } = req.query;
    const userId = req.user.id;
    const foods = await foodService.getRecommendedFoods(userId, limit || 20);
    res.json({ foods });
  } catch (err) {
    next(err);
  }
});

// ✅ SINGLE POST /api/food/log - Handles BOTH foodId & nutrition
router.post('/log', requireAuth, async (req, res, next) => {
  try {
    const { foodId, quantity, nutrition } = req.body;
    const userId = req.user.id;
    // ✅ Use frontend userId or default '123'
    const targetUserId = userId || '123';
    
    console.log('🍎 Food log:', {
      userId: targetUserId,
      foodId,
      food: nutrition?.name,
      quantity,
      carbs: nutrition?.carbsG
    });

    // ✅ Call YOUR foodService.logFood (matches backend)
    const result = await foodService.logFood(targetUserId, { 
      ...(nutrition || {}),
      foodId,
      quantity,
      loggedAt: new Date().toISOString()
    });

    res.status(201).json({ 
      success: true,
      message: `Logged ${nutrition?.name || 'food'} (+${result.spikeHeight?.toFixed(0) || 0}mg/dL)`,
      foodLogId: result.foodLogId,
      spikeHeight: result.spikeHeight,
      userId: userId
    });
  } catch (error) {
    console.error('❌ Food log error:', error);
    res.status(500).json({ 
      error: error.message,
      details: error.stack 
    });
  }
});

export default router;
