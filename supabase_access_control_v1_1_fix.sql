-- LamTrack Access Control V1.1 compatibility fix
-- Run this AFTER supabase_access_control_v1.sql. Safe to run more than once.

create or replace function public.admin_list_users()
returns table(
  user_id uuid,
  email text,
  full_name text,
  status text,
  role text,
  plan text,
  expires_at timestamptz,
  created_at timestamptz
)
language plpgsql security definer set search_path=public,auth as $$
begin
  if not public.is_lamtrack_admin(auth.uid()) then
    raise exception 'Not authorized';
  end if;
  return query
  select
    u.id::uuid,
    u.email::text,
    coalesce(u.raw_user_meta_data->>'full_name','User')::text,
    coalesce(a.status,'pending')::text,
    coalesce(a.role,'user')::text,
    coalesce(a.plan,'free')::text,
    a.expires_at::timestamptz,
    u.created_at::timestamptz
  from auth.users u
  left join public.app_access a on a.user_id=u.id
  order by u.created_at desc;
end; $$;

grant execute on function public.admin_list_users() to authenticated;

-- Keep owner/admin access usable even if a commercial expiry is present.
create or replace function public.current_user_has_lamtrack_access()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.app_access a
    where a.user_id=auth.uid()
      and (
        a.role in ('owner','super_admin')
        or (a.status='approved' and (a.expires_at is null or a.expires_at > now()))
      )
  );
$$;

grant execute on function public.current_user_has_lamtrack_access() to authenticated;
