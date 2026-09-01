-- ============================================================
-- AUTODROP™ — BANCO DE DADOS SUPABASE
-- Execute esta query inteira em um banco NOVO.
-- ============================================================

-- 1. LIMPEZA
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 2. CLIENTES
CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PEDIDOS
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    product_name TEXT NOT NULL DEFAULT 'Autodrop™',
    amount NUMERIC NOT NULL DEFAULT 499.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. PAGAMENTOS
CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    method TEXT NOT NULL CHECK (method IN ('Pix', 'Cartão', 'Boleto')),
    paid BOOLEAN NOT NULL DEFAULT FALSE,
    paid_at TIMESTAMPTZ
);

-- 5. ATIVAR RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- 6. PERMISSÕES
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON customers TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON orders TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON payments TO anon, authenticated;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO anon, authenticated;

-- ============================================================
-- 7. POLÍTICAS DE CUSTOMERS
-- ============================================================

CREATE POLICY "user insert customers"
ON customers
FOR INSERT
TO authenticated
WITH CHECK (TRUE);

CREATE POLICY "user select own customers"
ON customers
FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT customer_id
        FROM orders
        WHERE user_id = auth.uid()
    )
);

-- ============================================================
-- 8. POLÍTICAS DE ORDERS
-- ============================================================

CREATE POLICY "user insert own orders"
ON orders
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
);

CREATE POLICY "user select own orders"
ON orders
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
);

-- ============================================================
-- 9. POLÍTICAS DE PAYMENTS
-- ============================================================

CREATE POLICY "user insert own payments"
ON payments
FOR INSERT
TO authenticated
WITH CHECK (
    order_id IN (
        SELECT id
        FROM orders
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "user select own payments"
ON payments
FOR SELECT
TO authenticated
USING (
    order_id IN (
        SELECT id
        FROM orders
        WHERE user_id = auth.uid()
    )
);

-- ============================================================
-- FIM
-- ============================================================
