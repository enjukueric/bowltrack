-- ============================================================
-- Bowl Tracker — League "Note for Next Time" Migration
-- Run in Supabase SQL Editor
-- ============================================================

-- A rolling note per league (e.g. "stand 2 boards left of practice spot").
-- Shown as a reminder popup the next time a session is started for that
-- league, then cleared once the user acknowledges it.
ALTER TABLE leagues
  ADD COLUMN IF NOT EXISTS next_note TEXT;
