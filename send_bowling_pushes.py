"""
Bowl Track — Push Notification Sender
Checks for new reactions/comments and sends Web Push notifications to affected users.

Setup:
  pip install pywebpush requests
  Set SUPABASE_SERVICE_KEY below (Supabase dashboard → Settings → API → service_role)
  Set VAPID_CLAIMS email below
  Copy vapid_private.pem to the same directory

Schedule on Quatch: every 10 minutes
  python send_bowling_pushes.py
"""
import os
import json
import requests
from datetime import datetime, timezone

try:
    from pywebpush import webpush, WebPushException
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pywebpush'])
    from pywebpush import webpush, WebPushException

# ── Config — env vars take priority (used by GitHub Actions) ───────────────────
SUPABASE_URL      = 'https://mzjicrhoyftmzeqqjzbj.supabase.co'
SUPABASE_SVC_KEY  = os.environ.get('BOWL_SVC_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16amljcmhveWZ0bXplcXFqemJqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDA5MDYyMiwiZXhwIjoyMDg5NjY2NjIyfQ.GqF7ofTwuhPqGf3fTMsDAwMJeoTDXGdehQ-IxDBagkc')
VAPID_PRIVATE_KEY = os.environ.get('VAPID_KEY_FILE', 'vapid_private.pem')
VAPID_CLAIMS      = {'sub': 'mailto:eric@enjukuracing.com'}
STATE_FILE        = 'bowling_push_state.json'
APP_URL           = 'https://enjukueric.github.io/bowltrack/'
# When LOOKBACK_MINUTES is set, ignore state file and check that window instead
LOOKBACK_MINUTES  = int(os.environ.get('LOOKBACK_MINUTES', '0'))
# ───────────────────────────────────────────────────────────────────────────────

HEADERS = {
    'apikey': SUPABASE_SVC_KEY,
    'Authorization': f'Bearer {SUPABASE_SVC_KEY}',
}

def supa_get(table, params):
    r = requests.get(f'{SUPABASE_URL}/rest/v1/{table}', params=params, headers=HEADERS, timeout=10)
    return r.json() if r.ok else []

def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {'last_checked': '1970-01-01T00:00:00+00:00'}

def save_state(state):
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f)

def get_session_owner(session_id):
    rows = supa_get('sessions', {'id': f'eq.{session_id}', 'select': 'user_id'})
    return rows[0]['user_id'] if rows else None

def get_actor_name(user_id):
    rows = supa_get('profiles', {'user_id': f'eq.{user_id}', 'select': 'full_name'})
    return rows[0]['full_name'] if rows else 'Someone'

def get_push_subs(user_id):
    return supa_get('push_subscriptions', {'user_id': f'eq.{user_id}', 'select': '*'})

def send_push(sub, title, body):
    try:
        webpush(
            subscription_info={
                'endpoint': sub['endpoint'],
                'keys': {'p256dh': sub['p256dh'], 'auth': sub['auth_key']}
            },
            data=json.dumps({'title': title, 'body': body, 'url': APP_URL}),
            vapid_private_key=VAPID_PRIVATE_KEY,
            vapid_claims=VAPID_CLAIMS
        )
        print(f"  OK Push sent to endpoint ...{sub['endpoint'][-20:]}")
    except WebPushException as e:
        print(f"  FAIL Push failed: {e}")

def main():
    now = datetime.now(timezone.utc).isoformat()
    if LOOKBACK_MINUTES:
        since = datetime.fromtimestamp(datetime.now(timezone.utc).timestamp() - LOOKBACK_MINUTES * 60, tz=timezone.utc).isoformat()
        state = None
    else:
        state = load_state()
        since = state['last_checked']
    print(f"[{now[:19]}] Checking for activity since {since[:19]}")

    # New reactions
    reactions = supa_get('reactions', {'created_at': f'gt.{since}', 'select': '*'})
    print(f"  {len(reactions)} new reaction(s)")
    for r in reactions:
        if r['target_type'] != 'session':
            continue
        owner_id = get_session_owner(r['target_id'])
        if not owner_id or owner_id == r['user_id']:
            continue  # skip self-reactions
        actor = get_actor_name(r['user_id'])
        for sub in get_push_subs(owner_id):
            send_push(sub, 'Bowl Track', f"{actor} reacted {r['emoji']} to your session!")

    # New comments
    comments = supa_get('comments', {'created_at': f'gt.{since}', 'select': '*'})
    print(f"  {len(comments)} new comment(s)")
    for c in comments:
        if c['target_type'] != 'session':
            continue
        owner_id = get_session_owner(c['target_id'])
        if not owner_id or owner_id == c['user_id']:
            continue
        actor = get_actor_name(c['user_id'])
        preview = c['content'][:80] + ('…' if len(c['content']) > 80 else '')
        for sub in get_push_subs(owner_id):
            send_push(sub, 'Bowl Track', f'{actor}: {preview}')

    if state is not None:
        state['last_checked'] = now
        save_state(state)
    print('Done.')

if __name__ == '__main__':
    main()
