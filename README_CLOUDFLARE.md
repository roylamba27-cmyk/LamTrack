# LamTrack Finance App - Cloudflare Pages

## Isi package
- LamTrack V25.4.4 Commercial
- Premium 3D logo + animation
- Dynamic month/year filters
- Profile fix
- Commercial access control
- Supabase backend tetap digunakan
- Netlify config dihapus
- Cloudflare Pages `_redirects` dan `_headers` ditambahkan

## PENTING
`js/config.js` sengaja tidak disertakan. Pertahankan file `js/config.js` milik deployment yang sudah terhubung ke Supabase. Jangan memasukkan service-role key atau secret ke browser.

## Deploy yang direkomendasikan
Gunakan Cloudflare Pages dengan GitHub integration agar setiap push ke `main` otomatis deploy.

Build command:
`exit 0`

Build output directory:
`.`

Production branch:
`main`

## Custom domain
Setelah deployment:
Cloudflare Dashboard -> Workers & Pages -> project LamTrack -> Custom domains -> Set up a domain.

Untuk domain utama seperti `lamtrack.com`, domain harus ditambahkan sebagai zone Cloudflare dan nameserver diarahkan ke Cloudflare.

## Supabase Auth
Setelah domain aktif, ubah Site URL dan Redirect URLs di Supabase Authentication menjadi domain produksi baru.

Contoh:
`https://lamtrack.com`
`https://lamtrack.com/**`

Tambahkan URL localhost untuk development bila diperlukan.
