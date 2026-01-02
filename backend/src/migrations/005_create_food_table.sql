-- Create food_logs table
CREATE TABLE IF NOT EXISTS food_logs (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  food_name VARCHAR(255),
  carbs_g DECIMAL,
  sugar_g DECIMAL,
  protein_g DECIMAL,
  fat_g DECIMAL,
  fiber_g DECIMAL,
  calories INTEGER,
  glucose_impact_score DECIMAL,
  quantity DECIMAL,
  spike_height DECIMAL,
  logged_at TIMESTAMP DEFAULT NOW()
);
