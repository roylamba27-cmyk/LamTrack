# LamTrack V25.4 - Commercial Access Control

This build adds a secure Owner / Super Admin approval layer for selling LamTrack access manually.

## Flow
1. User registers and verifies email.
2. A `pending` access record is created automatically.
3. User cannot read/write financial tables until access is approved.
4. Owner / Super Admin sees the user in **Pusat Admin**.
5. After payment is confirmed, admin clicks **Approve** and selects the plan.
6. User can use LamTrack.
7. Admin can suspend or reject access later.

## First-time Supabase setup
Run `supabase_access_control_v1.sql` once in the Supabase SQL Editor.

Then find your own auth user ID:

```sql
select id,email from auth.users order by created_at desc;
```

Bootstrap the owner by replacing `YOUR_AUTH_USER_ID`:

```sql
update public.app_access
set status='approved', role='owner', plan='owner', approved_at=now()
where user_id='YOUR_AUTH_USER_ID';
```

Refresh LamTrack. The Owner will see **Pusat Admin**.

## Important
- This is manual payment verification. No payment gateway is included yet.
- Never put Supabase service-role keys or OpenAI API keys in the browser.
- `js/config.js` is intentionally excluded from deployment ZIPs.


## V25.4.2 FINAL
- Fixed `admin_list_users()` return-type compatibility for Supabase/PostgreSQL.
- Added `supabase_access_control_v1_1_fix.sql` migration.
- Owner/Super Admin access is not blocked by commercial expiry.
- Admin role and plan selectors are wired correctly.
- Sidebar navigation scrolls independently; Profile and Logout are forced visible and remain reachable on desktop and mobile.
- Mobile navigation uses a drawer + overlay and responsive content sizing.

- Final commercial build: responsive analytics spacing, mobile drawer reliability, and final logout visibility hardening.
