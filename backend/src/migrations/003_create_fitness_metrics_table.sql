CREATE TABLE fitness_metrics (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metric_type  TEXT NOT NULL,          -- 'bmi', 'steps', 'heart_rate', 'calories', etc.
  value        NUMERIC NOT NULL,       -- main numeric value
  unit         TEXT NOT NULL,          -- 'kg/m2', 'steps', 'bpm'
  source       TEXT,                   -- 'google_fit', 'apple_health', 'manual'
  extra        JSONB,                  -- optional: { "height_cm": 175, "weight_kg": 70 }
  recorded_at  TIMESTAMPTZ NOT NULL,   -- when it happened
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_fitness_metrics_user_time
  ON fitness_metrics (user_id, recorded_at DESC);
CREATE INDEX idx_fitness_metrics_user_type_time
  ON fitness_metrics (user_id, metric_type, recorded_at DESC);
