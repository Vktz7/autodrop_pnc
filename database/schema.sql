-- 1. TABELAS
create table customers (
    id          bigint generated always as identity primary key,
    name        text not null,
    address     text not null,
    created_at  timestamptz default now()
);

create table orders (
    id           bigint generated always as identity primary key,
    customer_id  bigint not null references customers(id),
    user_id      uuid not null references auth.users(id),
    product_name text not null default 'Autodrop™',
    amount       numeric not null default 499.00,
    created_at   timestamptz default now()
);

create table payments (
    id        bigint generated always as identity primary key,
    order_id  bigint not null references orders(id),
    method    text not null check (method in ('Pix', 'Cartão', 'Boleto')),
    paid      boolean not null default false,
    paid_at   timestamptz
);

-- 2. SEGURANÇA (Row Level Security)
alter table customers enable row level security;
alter table orders enable row level security;
alter table payments enable row level security;

-- Permissões de schema (necessário para anon/authenticated acessarem)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on customers to anon, authenticated;
grant select, insert, update, delete on orders to anon, authenticated;
grant select, insert, update, delete on payments to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

-- CUSTOMERS: qualquer usuário logado pode criar, só vê o cliente se ele for dono de algum pedido apontando pra esse customer_id
create policy "user insert customers" on customers
    for insert to authenticated
    with check (true);

create policy "user select own customers" on customers
    for select to authenticated
    using (
        id in (select customer_id from orders where user_id = auth.uid())
    );

-- ORDERS: só o dono pode inserir e ver seus pedidos
create policy "user insert own orders" on orders
    for insert to authenticated
    with check (user_id = auth.uid());

create policy "user select own orders" on orders
    for select to authenticated
    using (user_id = auth.uid());

-- PAYMENTS: só pode inserir e ver pagamentos de pedidos que são seus
create policy "user insert own payments" on payments
    for insert to authenticated
    with check (
        order_id in (select id from orders where user_id = auth.uid())
    );

create policy "user select own payments" on payments
    for select to authenticated
    using (
        order_id in (select id from orders where user_id = auth.uid())
    );
