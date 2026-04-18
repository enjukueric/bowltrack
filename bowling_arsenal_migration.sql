-- ============================================================
-- Bowl Tracker — Arsenal + Feature Migration
-- Run in Supabase SQL Editor
-- ============================================================

-- Ball Arsenal
CREATE TABLE IF NOT EXISTS balls (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  weight     NUMERIC(3,1),
  surface    TEXT CHECK (surface IN ('reactive','hybrid','urethane','particle','plastic')),
  color_hex  TEXT NOT NULL DEFAULT '#6C63FF',
  notes      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tracks which ball was used from which frame onward in a game
-- e.g. { game_id: X, ball_id: Y, from_frame: 1 } = "ball Y from frame 1 on"
-- Multiple rows per game = ball switch mid-game
CREATE TABLE IF NOT EXISTS game_ball_log (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  game_id    UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  ball_id    UUID REFERENCES balls(id) ON DELETE SET NULL,
  from_frame INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE balls ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_ball_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "balls_select" ON balls FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "balls_insert" ON balls FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "balls_update" ON balls FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "balls_delete" ON balls FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "game_ball_log_select" ON game_ball_log FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    JOIN leagues ON leagues.id = sessions.league_id
    WHERE games.id = game_ball_log.game_id AND leagues.user_id = auth.uid()
  )
);
CREATE POLICY "game_ball_log_insert" ON game_ball_log FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    JOIN leagues ON leagues.id = sessions.league_id
    WHERE games.id = game_ball_log.game_id AND leagues.user_id = auth.uid()
  )
);
CREATE POLICY "game_ball_log_delete" ON game_ball_log FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM games
    JOIN sessions ON sessions.id = games.session_id
    JOIN leagues ON leagues.id = sessions.league_id
    WHERE games.id = game_ball_log.game_id AND leagues.user_id = auth.uid()
  )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_balls_user_id        ON balls(user_id);
CREATE INDEX IF NOT EXISTS idx_game_ball_log_game   ON game_ball_log(game_id);
