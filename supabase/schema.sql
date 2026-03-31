-- ============================================================
-- South Style App — Supabase SQL Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- -------------------------------------------------------
-- 1. CUSTOM ENUM TYPES
-- -------------------------------------------------------

CREATE TYPE employee_role AS ENUM (
  'admin',
  'supervisor',
  'data_entry',
  'production'
);

CREATE TYPE attendance_status AS ENUM (
  'present',
  'absent',
  'late'
);

CREATE TYPE product_type AS ENUM (
  'tshirt',
  'tarpaulin',
  'sticker',
  'mug',
  'other'
);

CREATE TYPE order_status AS ENUM (
  'pending',
  'cutting',
  'printing',
  'done'
);

CREATE TYPE production_stage AS ENUM (
  'cutting',
  'printing'
);

-- -------------------------------------------------------
-- 2. TABLES
-- -------------------------------------------------------

-- employees -----------------------------------------------
CREATE TABLE employees (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id     UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  employee_id TEXT UNIQUE NOT NULL,
  full_name   TEXT NOT NULL,
  role        employee_role NOT NULL DEFAULT 'production',
  daily_rate  NUMERIC(10,2) NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  employees IS 'All staff accounts; auth_id links to Supabase Auth';
COMMENT ON COLUMN employees.employee_id IS 'Human-readable badge ID shown on login';

-- attendance ----------------------------------------------
CREATE TABLE attendance (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  date        DATE NOT NULL DEFAULT CURRENT_DATE,
  time_in     TIMESTAMPTZ,
  time_out    TIMESTAMPTZ,
  status      attendance_status NOT NULL DEFAULT 'absent',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (employee_id, date)
);

COMMENT ON TABLE attendance IS 'Populated by ZKTeco biometric middleware';

-- job_orders ----------------------------------------------
CREATE TABLE job_orders (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_name TEXT NOT NULL,
  product_type  product_type NOT NULL,
  quantity      INTEGER NOT NULL CHECK (quantity > 0),
  notes         TEXT,
  status        order_status NOT NULL DEFAULT 'pending',
  created_by    UUID NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- order_items ---------------------------------------------
CREATE TABLE order_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_order_id UUID NOT NULL REFERENCES job_orders(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  size         TEXT,
  quantity     INTEGER NOT NULL CHECK (quantity > 0)
);

-- production_logs -----------------------------------------
CREATE TABLE production_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_order_id UUID NOT NULL REFERENCES job_orders(id) ON DELETE CASCADE,
  employee_id  UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  stage        production_stage NOT NULL,
  quantity_done INTEGER NOT NULL CHECK (quantity_done > 0),
  logged_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -------------------------------------------------------
-- 3. INDEXES
-- -------------------------------------------------------

CREATE INDEX idx_attendance_employee_date ON attendance (employee_id, date);
CREATE INDEX idx_job_orders_status        ON job_orders (status);
CREATE INDEX idx_job_orders_created_by    ON job_orders (created_by);
CREATE INDEX idx_order_items_job_order    ON order_items (job_order_id);
CREATE INDEX idx_production_logs_job      ON production_logs (job_order_id);
CREATE INDEX idx_production_logs_employee ON production_logs (employee_id);

-- -------------------------------------------------------
-- 4. HELPER: get current user's role
-- -------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS employee_role
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT role FROM employees WHERE auth_id = auth.uid();
$$;

-- -------------------------------------------------------
-- 5. ROW LEVEL SECURITY
-- -------------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE employees       ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance      ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items     ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_logs ENABLE ROW LEVEL SECURITY;

-- ── employees ──────────────────────────────────────────

-- Admin & supervisor: read all employees
CREATE POLICY "admin_supervisor_read_employees"
  ON employees FOR SELECT
  USING (public.get_my_role() IN ('admin', 'supervisor'));

-- Any authenticated user can read their own row
CREATE POLICY "self_read_employee"
  ON employees FOR SELECT
  USING (auth_id = auth.uid());

-- ── attendance ─────────────────────────────────────────

-- Admin & supervisor: read all attendance
CREATE POLICY "admin_supervisor_read_attendance"
  ON attendance FOR SELECT
  USING (public.get_my_role() IN ('admin', 'supervisor'));

-- Employees can read their own attendance
CREATE POLICY "self_read_attendance"
  ON attendance FOR SELECT
  USING (
    employee_id = (SELECT id FROM employees WHERE auth_id = auth.uid())
  );

-- Service role (ZKTeco middleware) inserts via service_role key,
-- which bypasses RLS. No insert policy needed for end users.

-- ── job_orders ─────────────────────────────────────────

-- Admin & supervisor: full read
CREATE POLICY "admin_supervisor_read_orders"
  ON job_orders FOR SELECT
  USING (public.get_my_role() IN ('admin', 'supervisor'));

-- data_entry: read all orders
CREATE POLICY "data_entry_read_orders"
  ON job_orders FOR SELECT
  USING (public.get_my_role() = 'data_entry');

-- data_entry: insert orders
CREATE POLICY "data_entry_insert_orders"
  ON job_orders FOR INSERT
  WITH CHECK (public.get_my_role() = 'data_entry');

-- production: read orders that are in cutting or printing stage
CREATE POLICY "production_read_orders"
  ON job_orders FOR SELECT
  USING (
    public.get_my_role() = 'production'
    AND status IN ('cutting', 'printing')
  );

-- ── order_items ────────────────────────────────────────

-- Admin & supervisor: full read
CREATE POLICY "admin_supervisor_read_order_items"
  ON order_items FOR SELECT
  USING (public.get_my_role() IN ('admin', 'supervisor'));

-- data_entry: read and insert
CREATE POLICY "data_entry_read_order_items"
  ON order_items FOR SELECT
  USING (public.get_my_role() = 'data_entry');

CREATE POLICY "data_entry_insert_order_items"
  ON order_items FOR INSERT
  WITH CHECK (public.get_my_role() = 'data_entry');

-- production: read items for orders they can see
CREATE POLICY "production_read_order_items"
  ON order_items FOR SELECT
  USING (
    public.get_my_role() = 'production'
    AND job_order_id IN (
      SELECT id FROM job_orders WHERE status IN ('cutting', 'printing')
    )
  );

-- ── production_logs ────────────────────────────────────

-- Admin & supervisor: full read
CREATE POLICY "admin_supervisor_read_production_logs"
  ON production_logs FOR SELECT
  USING (public.get_my_role() IN ('admin', 'supervisor'));

-- production: insert their own logs
CREATE POLICY "production_insert_logs"
  ON production_logs FOR INSERT
  WITH CHECK (
    public.get_my_role() = 'production'
    AND employee_id = (SELECT id FROM employees WHERE auth_id = auth.uid())
  );

-- production: read their own logs
CREATE POLICY "production_read_own_logs"
  ON production_logs FOR SELECT
  USING (
    public.get_my_role() = 'production'
    AND employee_id = (SELECT id FROM employees WHERE auth_id = auth.uid())
  );
