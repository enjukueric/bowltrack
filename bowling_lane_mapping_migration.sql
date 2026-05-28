-- ============================================================
-- Bowl Tracker — Lane Mapping + Ball Speed Migration
-- Run in Supabase SQL Editor
-- ============================================================

-- Add lane_number to sessions (the starting/odd lane of the pair)
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS lane_number INTEGER;

-- Add per-roll ball speed to frames (optional, mph, recorded during play)
ALTER TABLE frames
  ADD COLUMN IF NOT EXISTS roll1_speed NUMERIC(4,1),
  ADD COLUMN IF NOT EXISTS roll2_speed NUMERIC(4,1),
  ADD COLUMN IF NOT EXISTS roll3_speed NUMERIC(4,1);
