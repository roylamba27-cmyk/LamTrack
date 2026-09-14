-- LamTrack V25.1 - real asset vault
create extension if not exists pgcrypto;

create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null default 'other',
  current_value numeric not null default 0,
  purchase_value numeric not null default 0,
  purchase_date date,
  icon text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.assets enable row level security;

drop policy if exists "assets_select_own" on public.assets;
drop policy if exists "assets_insert_own" on public.assets;
drop policy if exists "assets_update_own" on public.assets;
drop policy if exists "assets_delete_own" on public.assets;

create policy "assets_select_own" on public.assets for select to authenticated
  using (auth.uid() = user_id);
create policy "assets_insert_own" on public.assets for insert to authenticated
  with check (auth.uid() = user_id);
create policy "assets_update_own" on public.assets for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "assets_delete_own" on public.assets for delete to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on table public.assets to authenticated;
grant usage on schema public to authenticated;
