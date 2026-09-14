# LamTrack V13 Premium

Update dashboard + bills + analytics + settings.

## Yang baru
- Tagihan nyata: listrik, Spotify, ChatGPT, internet, dll.
- Tagihan punya edit/hapus, tanggal jatuh tempo, frekuensi, auto bayar, aktif/nonaktif.
- Bell notifikasi untuk budget >=80%, budget terlampaui, dan pengeluaran >=80% pemasukan.
- Analytics lebih premium + evaluasi keuangan + tombol Export PDF.
- Export PDF memakai dialog Print browser, pilih **Save as PDF**.
- Pengaturan dengan animasi, tema putih/gelap, warna aksen custom, bahasa Indonesia/English.
- Warna logo LamTrack tetap tidak berubah.

## Instalasi
1. Backup folder project LamTrack kamu.
2. Copy `index.html` ke root project.
3. Copy `js/app.js` menggantikan app.js.
4. Copy `css/style.css` menggantikan style.css.
5. Copy `css/toast.css` jika diperlukan.
6. Pertahankan `js/config.js` milikmu. Jangan diganti.
7. Pertahankan folder `assets/` dan logo LamTrack milikmu, atau gunakan logo dari paket ini.
8. Jalankan SQL `supabase_bills_v13.sql` di Supabase SQL Editor.
9. Pastikan GRANT authenticated untuk tabel bills ikut dijalankan. SQL migration sudah menyertakannya.
10. Jalankan `npx serve -l 3000`, lalu refresh dengan `Ctrl + Shift + R`.

## Catatan
Tagihan disimpan di Supabase sehingga data tetap per-user dan mengikuti Row Level Security. Budget tetap dipakai sebagai batas pengeluaran, sedangkan Bills dipakai sebagai pengingat pembayaran rutin. Dua hal ini sengaja dipisahkan supaya dashboard tidak lagi mencampur listrik dengan budget Food, karena manusia sudah cukup sering membuat kekacauan sendiri.

## Web Stable baseline
This package keeps `js/config.js` separate so your existing Supabase credentials are not overwritten. Copy/keep your working `js/config.js` beside `config.example.js` before running.

Stability fixes included:
- Budget page now calculates usage using the same period-aware budget logic as dashboard/notifications.
- Account statistics and account cards remain readable in both light and dark themes.
- Existing V14-style account animations are preserved.


## Logo revision
- Login uses a premium vertical LamTrack lockup with otter + Rp icon, LamTrack wordmark and leaf.
- Favicon / PWA icon uses otter + Rp only.
- In-app brand is simply `LamTrack`.
- `js/config.js` is intentionally excluded and must remain the user's existing Supabase configuration.
- Light-mode commercial admin cards now use explicit readable text/background colors.
