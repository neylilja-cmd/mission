// オフライン対応のサービスワーカー。
//
// 方針：いつも端末に保存した版ですぐに開き、裏でネットから最新版を取ってきて保存し直す。
// 更新は「次に開いたとき」から反映される。電波がなくても、一度開いたことがあれば使える。

const CACHE = 'mission-reward-v1';

// 保存の対象：このアプリ自身のファイルと、Flutter が使う日本語フォント（Google Fonts）。
const isCacheable = (url) =>
  url.origin === self.location.origin || url.hostname === 'fonts.gstatic.com';

self.addEventListener('install', (event) => {
  // 最低限、起動に必要な入口だけは先に保存しておく。
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(['./', 'index.html', 'flutter_bootstrap.js', 'manifest.json']))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // 方式を変えたときのために、古い名前の保存領域は消す。
      const keys = await caches.keys();
      await Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key)));
      await self.clients.claim();
    })()
  );
});

// ページから渡されたファイル一覧を保存する（初回起動時に読み込まれた分）。
self.addEventListener('message', (event) => {
  if (event.data?.type !== 'cache-urls') return;
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      for (const url of event.data.urls) {
        try {
          if (!isCacheable(new URL(url)) || (await cache.match(url))) continue;
          const response = await fetch(url);
          if (response.ok) await cache.put(url, response);
        } catch (_) {
          // 取れなかったものは、次に開いたときにまた試す。
        }
      }
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (!isCacheable(url)) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      // ページを開くとき（アドレス直打ち・ホーム画面から起動）は、入口の index.html として扱う。
      const key = request.mode === 'navigate' ? './' : request;
      const cached = await cache.match(key, { ignoreSearch: request.mode === 'navigate' });

      const update = fetch(request)
        .then((response) => {
          if (response.ok) cache.put(key, response.clone());
          return response;
        })
        .catch(() => undefined);

      if (cached) {
        // 保存済みの版をすぐ返し、裏で更新しておく。
        event.waitUntil(update);
        return cached;
      }
      const response = await update;
      return response ?? Response.error();
    })()
  );
});
