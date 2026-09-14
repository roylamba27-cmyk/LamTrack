# LamTrack Web - Permanent Deployment

LamTrack adalah static web app dengan Supabase sebagai backend/auth/database.

## 1. Siapkan config.js

Salin file kerja kamu:

`js/config.js`

ke folder ini. Jangan gunakan `config.example.js` sebagai config produksi tanpa mengisi URL dan anon key Supabase.

Struktur akhirnya harus:

- index.html
- css/
- js/app.js
- js/config.js
- assets/
- netlify.toml

## 2. Test lokal

```bash
npx serve -l 3000
```

Buka http://localhost:3000

## 3. Deploy Netlify

Login ke Netlify lalu buka Netlify Drop:
https://app.netlify.com/drop

Drag folder ini, bukan ZIP yang masih memiliki folder pembungkus lain.

Setelah publish, Netlify memberikan URL `*.netlify.app`.

## 4. Supabase Auth production URL

Di Supabase Dashboard -> Authentication -> URL Configuration:

- Site URL = URL production Netlify
- Additional Redirect URLs = URL production Netlify + `/**` bila dibutuhkan

Pertahankan localhost untuk development.

## 5. Custom domain

Di Netlify -> Domain management, tambahkan domain milikmu.

Setelah domain aktif, ubah Site URL Supabase ke domain final dan tambahkan redirect URL domain final.

## 6. AI Advisor

Advisor bawaan LamTrack saat ini berjalan dengan financial rules dari data Supabase. Fitur scan struk tetap memakai Supabase Edge Function `scan-receipt`.

Jika Advisor generatif OpenAI akan diaktifkan, API key WAJIB disimpan di backend/Edge Function, bukan di browser.

## V22 UI polish
- Browser `prompt()`, `confirm()`, and `alert()` dialogs are removed from the app flow.
- Forgot password now uses a modern LamTrack modal and shows a dedicated email-sent confirmation screen.
- Registration email verification now uses a modern confirmation modal.
- Change password now uses a modern modal with password confirmation and strength indicator.
- Password recovery links open the modern new-password modal automatically.
- Delete confirmations now use a modern LamTrack confirmation modal.


## V23 update
- Fixed dark-mode readability for Dashboard greeting, Investment portfolio hero, Analytics hero, and AI Advisor hero.
- Improved Supabase password-recovery handling by registering the auth listener before session loading and detecting recovery redirects.
- Reset links now return to the LamTrack root with `?reset=1`, then open the modern "Buat password baru" modal.
- User-owned `js/config.js` is intentionally NOT included. Keep the existing working Supabase config when deploying.

## V24 update
- Added personal JSON backup export in Pengaturan.
- Added installable web-app manifest and favicon.
- Added SPA fallback and safer no-index headers for a personal finance app.
- Added long-lived asset caching for stable static assets.
- Existing `js/config.js` is intentionally excluded from the package.

## V25 update
- Added Money Momentum dashboard card with average cashflow, spending, and cash runway indicators.
- Added Smart Checklist with prioritized financial actions.
- Added lightweight PWA service worker for faster repeat loading and offline app shell.
- Updated build marker to V25.
- Existing `js/config.js` remains intentionally excluded.

## V25.1 hotfix / premium release
- Fixed transaction save button visibility by making the modal body scrollable and the submit bar sticky.
- Redesigned savings contribution modal.
- Added premium click ripple/micro-interactions and richer animal/asset motion.
- Added dark-mode auth readability fixes.
- Replaced sidebar Pengaturan button with profile avatar/name entry.
- Added real Aset module for house, land, car, motorcycle, property, gold, jewelry, electronics and other assets.
- Added expanded Analytics budgeting performance report and LamTrack AI Insight summary.
- Added `supabase_assets_v25.sql`; run it once in Supabase SQL Editor before using Aset.
- Service worker cache registration bumped to V25.1.
- Existing `js/config.js` is intentionally excluded.
