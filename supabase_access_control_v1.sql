-- LamTrack Access Control V1
-- Purpose: gated commercial access + Owner/Super Admin monitoring.
-- Run this once in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.app_access (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','approved','rejected','suspended')),
  role text not null default 'user' check (role in ('user','super_admin','owner')),
  plan text not null default 'free' check (plan in ('free','premium','pro','owner')),
  expires_at timestamptz,
  notes text,
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists app_access_status_idx on public.app_access(status);
create index if not exists app_access_role_idx on public.app_access(role);

create or replace function public.touch_app_access()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop trigger if exists trg_touch_app_access on public.app_access;
create trigger trg_touch_app_access before update on public.app_access
for each row execute function public.touch_app_access();

create or replace function public.create_app_access_for_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.app_access(user_id, status, role, plan)
  values(new.id, 'pending', 'user', 'free')
  on conflict(user_id) do nothing;
  return new;
end; $$;

drop trigger if exists trg_create_app_access on auth.users;
create trigger trg_create_app_access after insert on auth.users
for each row execute function public.create_app_access_for_new_user();

-- Backfill existing accounts.
insert into public.app_access(user_id, status, role, plan)
select id, 'pending', 'user', 'free' from auth.users
on conflict(user_id) do nothing;

alter table public.app_access enable row level security;

drop policy if exists app_access_self_select on public.app_access;
create policy app_access_self_select on public.app_access
for select to authenticated using (auth.uid() = user_id);

-- SECURITY DEFINER helpers intentionally bypass RLS internally.
create or replace function public.is_lamtrack_admin(uid uuid default auth.uid())
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.app_access
    where user_id=uid and role in ('owner','super_admin')
  );
$$;

create or replace function public.get_my_access()
returns table(status text, role text, plan text, expires_at timestamptz, notes text)
language sql stable security definer set search_path=public as $$
  select a.status,a.role,a.plan,a.expires_at,a.notes
  from public.app_access a
  where a.user_id=auth.uid();
$$;

grant execute on function public.get_my_access() to authenticated;
grant execute on function public.is_lamtrack_admin(uuid) to authenticated;

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
  select u.id,u.email,coalesce(u.raw_user_meta_data->>'full_name','User'),
         coalesce(a.status,'pending'),coalesce(a.role,'user'),coalesce(a.plan,'free'),
         a.expires_at,u.created_at
  from auth.users u
  left join public.app_access a on a.user_id=u.id
  order by u.created_at desc;
end; $$;

grant execute on function public.admin_list_users() to authenticated;

create or replace function public.admin_set_access(
  target_user_id uuid,
  new_status text,
  new_plan text default null,
  new_expires_at timestamptz default null,
  new_notes text default null
)
returns public.app_access
language plpgsql security definer set search_path=public as $$
declare result public.app_access;
begin
  if not public.is_lamtrack_admin(auth.uid()) then raise exception 'Not authorized'; end if;
  if new_status not in ('pending','approved','rejected','suspended') then raise exception 'Invalid status'; end if;
  if new_plan is not null and new_plan not in ('free','premium','pro','owner') then raise exception 'Invalid plan'; end if;
  if target_user_id=auth.uid() and new_status<>'approved' then raise exception 'Admin cannot disable own access'; end if;
  update public.app_access set
    status=new_status,
    plan=coalesce(new_plan,plan),
    expires_at=new_expires_at,
    notes=coalesce(new_notes,notes),
    approved_at=case when new_status='approved' then now() else approved_at end,
    approved_by=case when new_status='approved' then auth.uid() else approved_by end
  where user_id=target_user_id
  returning * into result;
  if result.id is null then raise exception 'User access record not found'; end if;
  return result;
end; $$;

grant execute on function public.admin_set_access(uuid,text,text,timestamptz,text) to authenticated;

create or replace function public.admin_set_role(target_user_id uuid, new_role text)
returns public.app_access
language plpgsql security definer set search_path=public as $$
declare result public.app_access;
begin
  if not exists(select 1 from public.app_access where user_id=auth.uid() and role='owner') then
    raise exception 'Only owner can change roles';
  end if;
  if new_role not in ('user','super_admin','owner') then raise exception 'Invalid role'; end if;
  update public.app_access set role=new_role,
    plan=case when new_role='owner' then 'owner' when plan='owner' then 'premium' else plan end
  where user_id=target_user_id returning * into result;
  if result.id is null then raise exception 'User access record not found'; end if;
  return result;
end; $$;

grant execute on function public.admin_set_role(uuid,text) to authenticated;

-- Commercial gate: existing owner/admin can still use data; normal users need approved access.
create or replace function public.current_user_has_lamtrack_access()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.app_access a
    where a.user_id=auth.uid()
      and a.status='approved'
      and (a.expires_at is null or a.expires_at > now())
  );
$$;

grant execute on function public.current_user_has_lamtrack_access() to authenticated;

-- Restrictive policies add an AND-like access gate to existing per-user policies.
-- PostgreSQL 15+ supports restrictive RLS policies.

do $$
declare t text;
begin
  foreach t in array array['accounts','transactions','budgets','savings','saving_contributions','investments','bills','assets'] loop
    execute format('drop policy if exists lamtrack_access_gate on public.%I',t);
    execute format('create policy lamtrack_access_gate on public.%I as restrictive for all to authenticated using (public.current_user_has_lamtrack_access() or public.is_lamtrack_admin(auth.uid())) with check (public.current_user_has_lamtrack_access() or public.is_lamtrack_admin(auth.uid()))',t);
  end loop;
end $$;

grant select,insert,update,delete on public.app_access to authenticated;

-- IMPORTANT: bootstrap your owner manually after running this script.
-- 1) Find your own auth user ID:
-- select id,email from auth.users order by created_at desc;
-- 2) Replace YOUR_AUTH_USER_ID below and run:
-- update public.app_access set status='approved', role='owner', plan='owner', approved_at=now() where user_id='YOUR_AUTH_USER_ID';
