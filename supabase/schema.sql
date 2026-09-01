-- ============================================================
-- Autodrop™ / PNC — schema para Supabase
-- Rode este arquivo inteiro no SQL Editor do projeto.
--
-- IMPORTANTE:
-- Este script APAGA as tabelas atuais e recria tudo.
-- ============================================================

begin;

drop table if exists public.payments cascade;
drop table if exists public.orders cascade;
drop table if exists public.customers cascade;

-- ------------------------------------------------------------
-- 1. TABELAS
-- ------------------------------------------------------------

create table public.customers (
    id         bigint generated always as identity primary key,
    user_id    uuid not null references auth.users(id) on delete cascade,
    name       text not null check (length(trim(name)) between 2 and 120),
    address    text not null check (length(trim(address)) between 5 and 300),
    created_at timestamptz not null default now()
);

create table public.orders (
    id           bigint generated always as identity primary key,
    customer_id  bigint not null references public.customers(id) on delete restrict,
    user_id      uuid not null references auth.users(id) on delete cascade,
    product_name text not null default 'Autodrop™',
    amount       numeric(10,2) not null default 499.00 check (amount >= 0),
    created_at   timestamptz not null default now()
);

create table public.payments (
    id        bigint generated always as identity primary key,
    order_id  bigint not null references public.orders(id) on delete cascade,
    method    text not null check (method in ('Pix', 'Cartão', 'Boleto')),
    paid      boolean not null default false,
    paid_at   timestamptz
);

create index customers_user_id_idx on public.customers(user_id);
create index orders_user_id_idx on public.orders(user_id);
create index orders_customer_id_idx on public.orders(customer_id);
create index payments_order_id_idx on public.payments(order_id);

-- ------------------------------------------------------------
-- 2. RLS
-- ------------------------------------------------------------

alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.payments enable row level security;

-- Remova policies antigas, caso existam.
drop policy if exists "customers_insert_own" on public.customers;
drop policy if exists "customers_select_own" on public.customers;
drop policy if exists "orders_insert_own" on public.orders;
drop policy if exists "orders_select_own" on public.orders;
drop policy if exists "payments_insert_own" on public.payments;
drop policy if exists "payments_select_own" on public.payments;

-- CUSTOMERS
create policy "customers_insert_own"
on public.customers
for insert
to authenticated
with check (user_id = auth.uid());

create policy "customers_select_own"
on public.customers
for select
to authenticated
using (user_id = auth.uid());

-- ORDERS
create policy "orders_insert_own"
on public.orders
for insert
to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.customers c
        where c.id = customer_id
          and c.user_id = auth.uid()
    )
);

create policy "orders_select_own"
on public.orders
for select
to authenticated
using (user_id = auth.uid());

-- PAYMENTS
create policy "payments_insert_own"
on public.payments
for insert
to authenticated
with check (
    exists (
        select 1
        from public.orders o
        where o.id = order_id
          and o.user_id = auth.uid()
    )
);

create policy "payments_select_own"
on public.payments
for select
to authenticated
using (
    exists (
        select 1
        from public.orders o
        where o.id = order_id
          and o.user_id = auth.uid()
    )
);

-- ------------------------------------------------------------
-- 3. PERMISSÕES DO API ROLE
-- ------------------------------------------------------------

grant usage on schema public to anon, authenticated;
grant select, insert on public.customers to authenticated;
grant select, insert on public.orders to authenticated;
grant select, insert on public.payments to authenticated;
grant usage, select on all sequences in schema public to authenticated;

commit;

-- ============================================================
-- CONSULTA ADMINISTRATIVA
-- Rode separadamente no SQL Editor para conferir os pedidos.
-- ============================================================
--
-- select
--   o.id as pedido,
--   u.email as email_cliente,
--   c.name as nome,
--   c.address as endereco,
--   p.method as forma_pagamento,
--   case when p.paid then 'Pago' else 'Pendente' end as status,
--   o.amount as valor,
--   o.created_at
-- from public.orders o
-- join public.customers c on c.id = o.customer_id
-- left join public.payments p on p.order_id = o.id
-- join auth.users u on u.id = o.user_id
-- order by o.created_at desc;
