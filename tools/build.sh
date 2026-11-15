#!/bin/zsh
# Builds both iPad home-screen apps into docs/ (served by GitHub Pages):
#   index.html      -> docs/        (Claire's Adventures)
#   fire/index.html -> docs/fire/   (Fire Drill)
set -e
cd "${0:A:h}/.."
V=$(date +%Y%m%d%H%M%S)
build() { # src outdir appTitle themeColor
  local src=$1 out=$2 title=$3 color=$4
  mkdir -p $out
  {
  cat <<HEAD
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="theme-color" content="$color">
<link rel="manifest" href="manifest.json">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<link rel="icon" href="icon-192.png">
<style>[hidden]{display:none!important}</style>
</head>
<body>
HEAD
  cat $src
  cat <<'TAIL'
<script>
if ('serviceWorker' in navigator && location.protocol === 'https:') navigator.serviceWorker.register('sw.js').catch(() => {});
</script>
</body>
</html>
TAIL
  } > $out/index.html
  cat > $out/manifest.json <<JSON
{
  "name": "$title",
  "short_name": "$title",
  "start_url": "./",
  "scope": "./",
  "display": "fullscreen",
  "orientation": "landscape",
  "background_color": "$color",
  "theme_color": "$color",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
JSON
  cat > $out/sw.js <<SW
// Keeps the game playable offline; fetches fresh copies whenever online.
const CACHE = '${title// /-}-$V';
const CORE = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png', './apple-touch-icon.png'];
self.addEventListener('install', (e) => { e.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting())); });
self.addEventListener('activate', (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k.startsWith('${title// /-}-') && k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith(fetch(e.request).then((r) => { const copy = r.clone(); caches.open(CACHE).then((c) => c.put(e.request, copy)); return r; })
    .catch(() => caches.match(e.request, { ignoreSearch: true }).then((m) => m || caches.match('./index.html'))));
});
SW
}
build index.html docs "Claire" "#8e44d6"
build fire/index.html docs/fire "Fire Drill" "#c42a4a"
touch docs/.nojekyll
echo "built docs/ and docs/fire/ ($V)"
