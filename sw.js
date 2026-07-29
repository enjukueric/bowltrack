// Bowl Track Service Worker — handles caching + push notifications
const CACHE = 'bowltrack-v7';

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll([])));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (e.request.url.includes('supabase')) return;
  e.respondWith(caches.match(e.request).then(r => r || fetch(e.request)));
});

self.addEventListener('push', e => {
  if (!e.data) return;
  let data;
  try { data = e.data.json(); } catch { data = { title: 'Bowl Track', body: e.data.text() }; }
  e.waitUntil(
    self.registration.showNotification(data.title || 'Bowl Track', {
      body: data.body || '',
      icon: data.icon || '',
      data: { url: data.url || 'https://enjukueric.github.io/bowltrack/' }
    })
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const url = e.notification.data?.url || 'https://enjukueric.github.io/bowltrack/';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const c of list) {
        if (c.url.includes('bowltrack') && 'focus' in c) return c.focus();
      }
      return clients.openWindow(url);
    })
  );
});
