
-- Harden the legacy access RPC so direct RPC calls cannot bypass payment rules.
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
    plan=case when role='owner' then 'owner' else coalesce(new_plan,plan) end,
    expires_at=case when role in ('owner','super_admin') then null else new_expires_at end,
    approved_at=case when new_status='approved' then now() else approved_at end,
    approved_by=case when new_status='approved' then auth.uid() else approved_by end,
    notes=coalesce(new_notes,notes)
  where user_id=target_user_id
    and not (new_status='approved' and coalesce(case when role='owner' then 'owner' else coalesce(new_plan,plan) end,plan) in ('premium','pro') and payment_status<>'paid')
  returning * into result;
  if result.id is null then raise exception 'Premium/Pro requires verified payment, or user access record was not found'; end if;
  return result;
end; $$;

grant execute on function public.admin_set_access(uuid,text,text,timestamptz,text) to authenticated;

-- Owner cannot accidentally demote itself and lock the control center.
create or replace function public.admin_set_role(target_user_id uuid, new_role text)
returns public.app_access
language plpgsql security definer set search_path=public as $$
declare result public.app_access;
begin
  if not exists(select 1 from public.app_access where user_id=auth.uid() and role='owner') then
    raise exception 'Only owner can change roles';
  end if;
  if new_role not in ('user','super_admin','owner') then raise exception 'Invalid role'; end if;
  if target_user_id=auth.uid() and new_role<>'owner' then raise exception 'Owner cannot demote own account'; end if;
  update public.app_access set role=new_role,
    plan=case when new_role='owner' then 'owner' when plan='owner' then 'premium' else plan end
  where user_id=target_user_id returning * into result;
  if result.id is null then raise exception 'User access record not found'; end if;
  return result;
end; $$;

grant execute on function public.admin_set_role(uuid,text) to authenticated;

-- Payment is part of the access gate for Premium/Pro. Refund/unpaid therefore revokes access.
create or replace function public.current_user_has_lamtrack_access()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.app_access a
    where a.user_id=auth.uid()
      and (
        a.role in ('owner','super_admin')
        or (
          a.status='approved'
          and (a.expires_at is null or a.expires_at > now())
          and (a.plan='free' or a.payment_status='paid')
        )
      )
  );
$$;

grant execute on function public.current_user_has_lamtrack_access() to authenticated;


-- Final admin listing: show Expired / Payment Pending as operational states.
create or replace function public.admin_list_users()
returns table(
  user_id uuid, email text, full_name text, status text, role text, plan text,
  expires_at timestamptz, created_at timestamptz, payment_status text,
  payment_amount numeric, payment_reference text, paid_at timestamptz, payment_notes text
)
language plpgsql security definer set search_path=public,auth as $$
begin
  if not public.is_lamtrack_admin(auth.uid()) then raise exception 'Not authorized'; end if;
  return query
  select
    u.id::uuid,
    u.email::text,
    coalesce(u.raw_user_meta_data->>'full_name','User')::text,
    case
      when a.status='approved' and a.role not in ('owner','super_admin')
        and a.plan in ('premium','pro') and coalesce(a.payment_status,'unpaid') <> 'paid' then 'payment_pending'
      when a.status='approved' and a.role not in ('owner','super_admin')
        and a.expires_at is not null and a.expires_at <= now() then 'expired'
      else coalesce(a.status,'pending')
    end::text,
    coalesce(a.role,'user')::text,
    coalesce(a.plan,'free')::text,
    a.expires_at::timestamptz,
    u.created_at::timestamptz,
    coalesce(a.payment_status,'unpaid')::text,
    coalesce(a.payment_amount,0)::numeric,
    a.payment_reference::text,
    a.paid_at::timestamptz,
    a.payment_notes::text
  from auth.users u
  left join public.app_access a on a.user_id=u.id
  order by u.created_at desc;
end; $$;

grant execute on function public.admin_list_users() to authenticated;

-- Return a dynamic access state to the frontend without changing the table enum.
drop function if exists public.get_my_access();
create or replace function public.get_my_access()
returns table(status text, role text, plan text, expires_at timestamptz, notes text)
language sql stable security definer set search_path=public as $$
  select
    case
      when a.role not in ('owner','super_admin') and a.status='approved'
        and a.plan in ('premium','pro') and coalesce(a.payment_status,'unpaid') <> 'paid' then 'payment_pending'
      when a.role not in ('owner','super_admin') and a.status='approved'
        and a.expires_at is not null and a.expires_at <= now() then 'expired'
      else a.status
    end::text,
    a.role,
    a.plan,
    a.expires_at,
    a.notes
  from public.app_access a
  where a.user_id=auth.uid();
$$;

grant execute on function public.get_my_access() to authenticated;

-- Final security hardening: a Super Admin cannot alter the Owner account.
create or replace function public.admin_set_commercial(
  target_user_id uuid,
  new_status text,
  new_plan text,
  new_expires_at timestamptz default null,
  new_payment_status text default 'unpaid',
  new_payment_amount numeric default 0,
  new_payment_reference text default null,
  new_payment_notes text default null
)
returns public.app_access
language plpgsql security definer set search_path=public as $$
declare result public.app_access; target_role text;
begin
  if not public.is_lamtrack_admin(auth.uid()) then raise exception 'Not authorized'; end if;
  select role into target_role from public.app_access where user_id=target_user_id;
  if target_role is null then raise exception 'User access record not found'; end if;
  if target_role='owner' and not exists(select 1 from public.app_access where user_id=auth.uid() and role='owner') then
    raise exception 'Only owner can manage the owner account';
  end if;
  if new_status not in ('pending','approved','rejected','suspended') then raise exception 'Invalid status'; end if;
  if new_plan not in ('free','premium','pro','owner') then raise exception 'Invalid plan'; end if;
  if new_payment_status not in ('unpaid','pending','paid','refunded') then raise exception 'Invalid payment status'; end if;
  if target_user_id=auth.uid() and new_status<>'approved' then raise exception 'Admin cannot disable own access'; end if;
  if target_user_id=auth.uid() and new_plan<>'owner' then raise exception 'Owner cannot downgrade own plan'; end if;
  if target_role='super_admin' and new_plan='owner' then raise exception 'Owner plan is reserved for the Owner role'; end if;
  if new_plan in ('premium','pro') and new_status='approved' and new_payment_status<>'paid' then
    raise exception 'Premium/Pro access requires verified payment';
  end if;
  update public.app_access set
    status=new_status,
    plan=case when role='owner' then 'owner' else new_plan end,
    expires_at=case when role in ('owner','super_admin') then null else new_expires_at end,
    payment_status=case when role in ('owner','super_admin') then 'paid' else new_payment_status end,
    payment_amount=greatest(coalesce(new_payment_amount,0),0),
    payment_reference=nullif(trim(coalesce(new_payment_reference,'')),''),
    paid_at=case when new_payment_status='paid' then coalesce(paid_at,now()) else null end,
    payment_notes=nullif(trim(coalesce(new_payment_notes,'')),''),
    approved_at=case when new_status='approved' then now() else approved_at end,
    approved_by=case when new_status='approved' then auth.uid() else approved_by end
  where user_id=target_user_id
  returning * into result;
  if result.id is null then raise exception 'User access record not found'; end if;
  return result;
end; $$;

grant execute on function public.admin_set_commercial(uuid,text,text,timestamptz,text,numeric,text,text) to authenticated;
