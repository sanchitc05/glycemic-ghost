-- ✅ Add ALL Dexcom CGM columns to dexcom_tokens
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS system_time TIMESTAMPTZ;
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS display_time TIMESTAMPTZ;
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS value INTEGER;
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS realtime_value INTEGER;
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS smoothed_value INTEGER;
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS trend_rate FLOAT;
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS status VARCHAR(50);
ALTER TABLE dexcom_tokens ADD COLUMN IF NOT EXISTS trend VARCHAR(50);

-- ✅ Indexes for performance
CREATE INDEX IF NOT EXISTS idx_dexcom_system_time ON dexcom_tokens(system_time);
CREATE INDEX IF NOT EXISTS idx_dexcom_user_time ON dexcom_tokens(user_id, system_time DESC);
