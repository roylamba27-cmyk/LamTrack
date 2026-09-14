create table if not exists public.bills (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  provider text,
  amount numeric(18,2) not null default 0 check (amount >= 0),
  due_date date not null,
  frequency text not null default 'monthly' check (frequency in ('weekly','monthly','quarterly','yearly')),
  icon text default '🧾',
  is_active boolean not null default true,
  autopay boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists bills_user_due_idx on public.bills(user_id,due_date);
alter table public.bills enable row level security;
drop policy if exists "bills_select_own" on public.bills;
drop policy if exists "bills_insert_own" on public.bills;
drop policy if exists "bills_update_own" on public.bills;
drop policy if exists "bills_delete_own" on public.bills;
create policy "bills_select_own" on public.bills for select using (auth.uid()=user_id);
create policy "bills_insert_own" on public.bills for insert with check (auth.uid()=user_id);
create policy "bills_update_own" on public.bills for update using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "bills_delete_own" on public.bills for delete using (auth.uid()=user_id);

grant select, insert, update, delete on table public.bills to authenticated;
