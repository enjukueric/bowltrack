-- ============================================================
-- Push notification state tracking
-- Run once in the Supabase SQL editor
-- ============================================================
-- The GitHub Actions runner that sends push notifications is ephemeral
-- (no local disk persists between runs), and its schedule is unreliable
-- (cron says every 10 min, but GitHub often delays scheduled runs by
-- 1-2 hours on low-traffic repos). This table lets send_bowling_pushes.py
-- track "last checked" in Supabase instead of a local file, so it always
-- picks up exactly where the last successful run left off, no matter how
-- irregular the actual run cadence is.

CREATE TABLE IF NOT EXISTS push_notif_state (
  id           INTEGER PRIMARY KEY DEFAULT 1,
  last_checked TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed the single row starting from now, so the first run under the new
-- logic doesn't blast a backlog of old reactions/comments as notifications.
INSERT INTO push_notif_state (id, last_checked)
VALUES (1, NOW())
ON CONFLICT (id) DO NOTHING;

-- Script authenticates with the service_role key (bypasses RLS), so this
-- just locks the table down from the public anon/authenticated roles.
ALTER TABLE push_notif_state ENABLE ROW LEVEL SECURITY;
