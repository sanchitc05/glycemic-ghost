import { getPgPool } from '../config/postgres.js';

export async function getEmergencyContacts(userId) {
  const pool = getPgPool();
  const result = await pool.query(
    `SELECT id, name, phone, relation, priority 
     FROM emergency_contacts 
     WHERE user_id = $1 
     ORDER BY priority ASC`,
    [userId]
  );
  return result.rows;
}

export async function addEmergencyContact(userId, contact) {
  const pool = getPgPool();
  const result = await pool.query(
    `INSERT INTO emergency_contacts (user_id, name, phone, relation, priority)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [userId, contact.name, contact.phone, contact.relation || null, contact.priority || 1]
  );
  return result.rows[0];
}

export async function deleteEmergencyContact(userId, contactId) {
  const pool = getPgPool();
  await pool.query(
    `DELETE FROM emergency_contacts 
     WHERE user_id = $1 AND id = $2`,
    [userId, contactId]
  );
}

export async function getAlertSettings(userId) {
  const pool = getPgPool();
  let result = await pool.query(
    `SELECT * FROM user_alert_settings WHERE user_id = $1`,
    [userId]
  );
  if (result.rows.length === 0) {
    // Create defaults
    result = await pool.query(
      `INSERT INTO user_alert_settings (user_id) VALUES ($1) RETURNING *`,
      [userId]
    );
  }
  return result.rows[0];
}

export async function updateAlertSettings(userId, settings) {
  const pool = getPgPool();
  const result = await pool.query(
    `UPDATE user_alert_settings 
     SET low_threshold = $2, urgent_low = $3, high_threshold = $4, 
         urgent_high = $5, rate_change_mg_min = $6, predictive_minutes = $7
     WHERE user_id = $1
     RETURNING *`,
    [userId, settings.low_threshold, settings.urgent_low, settings.high_threshold,
     settings.urgent_high, settings.rate_change_mg_min, settings.predictive_minutes]
  );
  return result.rows[0];
}
