ALTER TABLE food_logs DROP COLUMN IF EXISTS food_id;
ALTER TABLE dexcom_tokens DROP COLUMN IF EXISTS food_id;

-- ✅ STEP 2: Add FRESH INTEGER columns
ALTER TABLE food_logs ADD COLUMN food_id INTEGER;
ALTER TABLE dexcom_tokens ADD COLUMN food_id INTEGER;

ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS food_log_id INTEGER;

CREATE INDEX IF NOT EXISTS idx_food_logs_food_id ON food_logs(food_id);
CREATE INDEX IF NOT EXISTS idx_dexcom_food_id ON dexcom_tokens(food_id);
CREATE INDEX IF NOT EXISTS idx_dexcom_food_log_id ON dexcom_tokens(food_log_id);