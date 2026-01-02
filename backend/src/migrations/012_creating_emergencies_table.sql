DROP TABLE IF EXISTS emergency_contacts CASCADE;
DROP TABLE IF EXISTS user_alert_settings CASCADE;

CREATE TABLE user_alert_settings (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,  -- Changed to UUID
  low_threshold INTEGER DEFAULT 70,
  urgent_low INTEGER DEFAULT 55,
  high_threshold INTEGER DEFAULT 250,
  urgent_high INTEGER DEFAULT 350,
  rate_change_mg_min INTEGER DEFAULT 3,
  predictive_minutes INTEGER DEFAULT 20,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE emergency_contacts (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,  -- Changed to UUID
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  relation VARCHAR(50),
  priority INTEGER DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, phone)
);

CREATE INDEX idx_contacts_user ON emergency_contacts(user_id);
CREATE INDEX idx_alerts_user ON user_alert_settings(user_id);
