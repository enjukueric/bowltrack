-- ============================================================
-- Bowl Tracker — Lane Moves (where you stand / aim, by board number)
-- Run in Supabase SQL Editor. Safe to re-run.
-- Boards are 1-39, numbered right-to-left for a right-hander (board 20 = center).
-- feet_board   = board your left foot is on (or the spot you slide on)
-- target_board = board you aim at (arrows are boards 5,10,15,20,25,30,35)
-- kind         = 'start' (your starting spot) or 'move' (a change mid-session)
-- prev_*       = the position you moved FROM (so the size/direction of a move is known)
-- ============================================================
CREATE TABLE IF NOT EXISTS lane_moves (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  game_id      UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  frame_number INTEGER NOT NULL CHECK (frame_number BETWEEN 1 AND 10),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE lane_moves
  ADD COLUMN IF NOT EXISTS kind            TEXT NOT NULL DEFAULT 'move' CHECK (kind IN ('start','move')),
  ADD COLUMN IF NOT EXISTS feet_board      INTEGER CHECK (feet_board BETWEEN 1 AND 39),
  ADD COLUMN IF NOT EXISTS target_board    INTEGER CHECK (target_board BETWEEN 1 AND 39),
  ADD COLUMN IF NOT EXISTS prev_feet_board   INTEGER CHECK (prev_feet_board BETWEEN 1 AND 39),
  ADD COLUMN IF NOT EXISTS prev_target_board INTEGER CHECK (prev_target_board BETWEEN 1 AND 39),
  ADD COLUMN IF NOT EXISTS note            TEXT;

ALTER TABLE lane_moves ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lane_moves_select" ON lane_moves;
DROP POLICY IF EXISTS "lane_moves_insert" ON lane_moves;
DROP POLICY IF EXISTS "lane_moves_update" ON lane_moves;
DROP POLICY IF EXISTS "lane_moves_delete" ON lane_moves;

CREATE POLICY "lane_moves_select" ON lane_moves FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    LEFT JOIN leagues ON leagues.id = sessions.league_id
    WHERE games.id = lane_moves.game_id
      AND (sessions.user_id = auth.uid() OR leagues.user_id = auth.uid())
  )
);
CREATE POLICY "lane_moves_insert" ON lane_moves FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    LEFT JOIN leagues ON leagues.id = sessions.league_id
    WHERE games.id = lane_moves.game_id
      AND (sessions.user_id = auth.uid() OR leagues.user_id = auth.uid())
  )
);
CREATE POLICY "lane_moves_update" ON lane_moves FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    LEFT JOIN leagues ON leagues.id = sessions.league_id
    WHERE games.id = lane_moves.game_id
      AND (sessions.user_id = auth.uid() OR leagues.user_id = auth.uid())
  )
);
CREATE POLICY "lane_moves_delete" ON lane_moves FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    LEFT JOIN leagues ON leagues.id = sessions.league_id
    WHERE games.id = lane_moves.game_id
      AND (sessions.user_id = auth.uid() OR leagues.user_id = auth.uid())
  )
);

CREATE INDEX IF NOT EXISTS idx_lane_moves_game ON lane_moves(game_id);
