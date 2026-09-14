const CACHE='lamtrack-v25-4-4-logo-dynamic-date-3d';
const SHELL=['./','./index.html','./css/style.css','./css/toast.css','./js/app.js','./assets/lamtrack-logo.png','./assets/lamtrack-icon.png','./assets/lamtrack-wordmark.png','./assets/lamtrack-login-logo.png','./assets/lamtrack-login-logo-dark.png','./assets/lamtrack-brand.png','./assets/lamtrack-brand-dark.png','./assets/lamtrack-icon-1024.png','./manifest.webmanifest'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(SHELL)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{
  const u=new URL(e.request.url);
  if(u.origin!==location.origin)return;
  e.respondWith(caches.match(e.request).then(cached=>cached||fetch(e.request).then(r=>{
    const copy=r.clone();
    caches.open(CACHE).then(c=>c.put(e.request,copy));
    return r;
  }).catch(()=>caches.match('./index.html'))));
});
