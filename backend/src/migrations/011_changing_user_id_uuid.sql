ALTER TABLE dexcom_tokens 
DROP COLUMN user_id;

ALTER TABLE dexcom_tokens 
ADD COLUMN user_id UUID;