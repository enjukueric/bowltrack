-- ============================================================
-- League End / Season tracking migration
-- Run once in the Supabase SQL editor
-- ============================================================

-- Optional grouping label so seasons of the "same" league (e.g. "Tuesday
-- Winter League" every year) can be compared across years even though each
-- season is its own row in `leagues`. Defaults to the league name if left
-- blank in the app.
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS series_key TEXT;

-- Season scheduling. end_date is authoritative for auto-ending; num_weeks
-- is just a convenience the app uses to compute end_date from start_date
-- (leagues run 16, 30, or other week counts).
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS num_weeks  INTEGER;
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS end_date   DATE;

-- Set once a league/season is ended (auto, once end_date has passed, or
-- manually via "End League Now"). final_stats is a permanent snapshot of
-- the season's stats saved at end time, so the recap survives even if
-- underlying sessions/games are later pruned.
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS ended_at    TIMESTAMPTZ;
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS final_stats JSONB;

CREATE INDEX IF NOT EXISTS idx_leagues_series_key ON leagues(series_key);
CREATE INDEX IF NOT EXISTS idx_leagues_end_date   ON leagues(end_date);
