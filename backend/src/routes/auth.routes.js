import { Router } from 'express';
import * as authService from '../services/auth.service.js';

const router = Router();

// POST /api/auth/register
router.post('/register', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const { user, token } = await authService.register({ email, password });

    res.status(201).json({
      user: { id: user.id, email: user.email },
      token,
    });
  } catch (err) {
    // unique violation
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already in use' });
    }
    next(err);
  }
});

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const { user, token } = await authService.login({ email, password });

    res.json({
      user: { id: user.id, email: user.email },
      token,
    });
  } catch (err) {
    if (err.message === 'Invalid credentials') {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    next(err);
  }
});

export default router;
