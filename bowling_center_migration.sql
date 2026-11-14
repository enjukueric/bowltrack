-- ============================================================
-- Bowl Tracker — Bowling Center column (for Ball Tracker center filter)
-- Run in Supabase SQL Editor. Safe to re-run.
-- ============================================================
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS center TEXT;
