
-- Add columns to track food events in EGVs
ALTER TABLE dexcom_tokens
ADD COLUMN IF NOT EXISTS event_source VARCHAR(50) DEFAULT 'CGM',
ADD COLUMN IF NOT EXISTS food_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS food_name VARCHAR(255);
