CREATE TABLE foods (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  serving_size TEXT NOT NULL,       -- "1 chapati (50g)", "1 apple (100g)"
  calories   INTEGER NOT NULL,
  carbs_g    NUMERIC NOT NULL,
  category   TEXT                   -- 'fruit', 'grain', 'fast_food', etc.
);

CREATE TABLE food_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  food_id     UUID NOT NULL REFERENCES foods(id),
  quantity    NUMERIC NOT NULL,      -- e.g. 2 chapatis
  logged_at   TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
