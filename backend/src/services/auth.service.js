import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { getPgPool } from '../config/postgres.js';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';
const JWT_EXPIRES_IN = '7d';

export async function register({ email, password }) {
  const pool = getPgPool();
  const passwordHash = await bcrypt.hash(password, 10);

  const insertUser = `
    INSERT INTO users (email, password_hash)
    VALUES ($1, $2)
    RETURNING id, email, created_at
  `;

  const { rows } = await pool.query(insertUser, [email.toLowerCase(), passwordHash]);
  const user = rows[0];

  // ✅ NEW USER = FRESH START (no demo data copy)
  console.log(`👤 New user registered: ${user.id}`);

  const token = signToken(user.id);
  return { user, token };
}

export async function login({ email, password }) {
  const pool = getPgPool();
  const query = `
    SELECT id, email, password_hash, created_at
    FROM users WHERE email = $1
  `;
  const { rows } = await pool.query(query, [email.toLowerCase()]);
  const user = rows[0];

  if (!user) {
    throw new Error('Invalid credentials');
  }

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) {
    throw new Error('Invalid credentials');
  }

  // ✅ DYNAMIC: Check if user has Dexcom data
  const dexcomCount = await pool.query(
    `SELECT COUNT(*) as count FROM dexcom_tokens WHERE user_id = $1`, 
    [user.id]
  );
  
  if (parseInt(dexcomCount.rows[0].count) === 0) {
    console.log(`👤 ${user.email} - No CGM setup. Guide to Dexcom connect.`);
  } else {
    console.log(`📈 ${user.email} - CGM active (${user.id})`);
  }

  const token = signToken(user.id);
  return { user, token };
}

function signToken(userId) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}
