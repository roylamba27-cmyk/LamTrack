
## V25.4.2 deployment notes

The web build includes:
- analytics spacing refinement
- persistent sidebar logout area
- responsive navigation for desktop/tablet/mobile
- commercial access management modal
- payment verification + amount/reference/notes
- Free/Premium/Pro package control
- expiry date with automatic frontend + RLS enforcement
- refunded/unpaid Premium/Pro access blocked
- admin monitoring KPIs
- Owner protection from Super Admin changes
- Owner cannot accidentally demote itself

### Database order
Run these in Supabase SQL Editor, in order:
1. `supabase_access_control_v1.sql` (only if not already installed)
2. `supabase_access_control_v1_1_fix.sql`
3. `supabase_commercial_v1_2.sql`

Do not put Supabase service-role/secret keys into the website. `js/config.js` is intentionally excluded from the ZIP.
