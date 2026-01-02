import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';



export function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const payload = jwt.verify(token, JWT_SECRET); // { userId }

    req.user = { id: payload.userId };

    next();
  } catch (err) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
}
