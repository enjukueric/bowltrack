-- ============================================================
-- Disk IO fix: missing indexes on social tables
-- Run once in the Supabase SQL editor (project: mzjicrhoyftmzeqqjzbj)
-- ============================================================
-- bowling_social_migration.sql created follows/reactions/comments/
-- push_subscriptions with zero indexes beyond primary keys. Every app
-- feed load and the send_bowling_pushes.py cron (every 10 min, 24/7)
-- force a sequential scan of these tables. Adding the indexes these
-- queries actually filter on turns those into index scans.

-- reactions / comments: cron filters "created_at > since" every 10 min;
-- app feed filters "target_type = ... AND target_id IN (...)"
CREATE INDEX IF NOT EXISTS idx_reactions_created_at ON reactions(created_at);
CREATE INDEX IF NOT EXISTS idx_comments_created_at  ON comments(created_at);
CREATE INDEX IF NOT EXISTS idx_reactions_target ON reactions(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_comments_target  ON comments(target_type, target_id);

-- push_subscriptions: cron + app both filter by user_id
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id ON push_subscriptions(user_id);

-- follows: app queries filter by follower_id/following_id directly, and
-- the sessions_followers_select / games_followers_select RLS policies
-- run a "follower_id = auth.uid()" subquery against this table on every
-- row of every sessions/games select for a user who follows anyone.
CREATE INDEX IF NOT EXISTS idx_follows_follower_id  ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);
