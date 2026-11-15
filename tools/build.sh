#!/bin/zsh
# Builds the iPad home-screen app into docs/ (served by GitHub Pages) from index.html.
set -e
cd "${0:A:h}/.."
V=$(date +%Y%m%d%H%M%S)
{
cat <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Claire">
<meta name="theme-color" content="#8e44d6">
<link rel="manifest" href="manifest.json">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<link rel="icon" href="icon-192.png">
<style>[hidden]{display:none!important}</style>
</head>
<body>
HEAD
cat index.html
cat <<'TAIL'
<script>
if ('serviceWorker' in navigator && location.protocol === 'https:') navigator.serviceWorker.register('sw.js').catch(() => {});
</script>
</body>
</html>
TAIL
} > docs/index.html
cat > docs/manifest.json <<'JSON'
{
  "name": "Claire's Adventures",
  "short_name": "Claire",
  "start_url": "./",
  "scope": "./",
  "display": "fullscreen",
  "orientation": "landscape",
  "background_color": "#8e44d6",
  "theme_color": "#8e44d6",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
JSON
cat > docs/sw.js <<SW
// Keeps the game playable offline; fetches fresh copies whenever online.
const CACHE = 'claire-$V';
const CORE = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png', './apple-touch-icon.png'];
self.addEventListener('install', (e) => { e.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting())); });
self.addEventListener('activate', (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith(fetch(e.request).then((r) => { const copy = r.clone(); caches.open(CACHE).then((c) => c.put(e.request, copy)); return r; })
    .catch(() => caches.match(e.request, { ignoreSearch: true }).then((m) => m || caches.match('./index.html'))));
});
SW
touch docs/.nojekyll
echo "built docs/ ($V)"
