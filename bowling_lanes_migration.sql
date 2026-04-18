-- ============================================================
-- Bowl Tracker — Lane Conditions + Shot Tendency Migration
-- Run in Supabase SQL Editor
-- ============================================================

-- Add lane condition columns to sessions
ALTER TABLE sessions
  ADD COLUMN IF NOT EXISTS lanes         TEXT,
  ADD COLUMN IF NOT EXISTS pattern       TEXT CHECK (pattern IN ('house','sport','challenge','flooding','unknown')),
  ADD COLUMN IF NOT EXISTS pattern_length TEXT CHECK (pattern_length IN ('short','medium','long','unknown')),
  ADD COLUMN IF NOT EXISTS condition     TEXT CHECK (condition IN ('fresh','breaking','burned','unknown')),
  ADD COLUMN IF NOT EXISTS lane_notes    TEXT;

-- Shot tendency log per game
CREATE TABLE IF NOT EXISTS shot_logs (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  game_id      UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  start_board  INTEGER CHECK (start_board BETWEEN 1 AND 39),
  target_arrow INTEGER CHECK (target_arrow BETWEEN 1 AND 7),
  reaction     TEXT CHECK (reaction IN ('left','flush','right','early','late','inconsistent')),
  adjustment   TEXT CHECK (adjustment IN ('move_left','move_right','target','speed_slow','speed_fast','none')),
  adj_boards   INTEGER,
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE shot_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shot_logs_select" ON shot_logs FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    JOIN leagues  ON leagues.id  = sessions.league_id
    WHERE games.id = shot_logs.game_id AND leagues.user_id = auth.uid()
  )
);
CREATE POLICY "shot_logs_insert" ON shot_logs FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    JOIN leagues  ON leagues.id  = sessions.league_id
    WHERE games.id = shot_logs.game_id AND leagues.user_id = auth.uid()
  )
);
CREATE POLICY "shot_logs_update" ON shot_logs FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    JOIN leagues  ON leagues.id  = sessions.league_id
    WHERE games.id = shot_logs.game_id AND leagues.user_id = auth.uid()
  )
);
CREATE POLICY "shot_logs_delete" ON shot_logs FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    JOIN leagues  ON leagues.id  = sessions.league_id
    WHERE games.id = shot_logs.game_id AND leagues.user_id = auth.uid()
  )
);

-- One shot log per game (upsert target)
CREATE UNIQUE INDEX IF NOT EXISTS idx_shot_logs_game_unique ON shot_logs(game_id);

CREATE INDEX IF NOT EXISTS idx_shot_logs_game ON shot_logs(game_id);
