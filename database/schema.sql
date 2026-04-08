-- ============================================================
-- FinTrack — Supabase PostgreSQL Schema
-- Run these commands in your Supabase SQL Editor (in order).
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- 1. USER PROFILES
-- Extends Supabase Auth with app-specific profile data.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email        TEXT NOT NULL,
    display_name TEXT,
    avatar_url   TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Auto-create profile on signup (Supabase trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();


-- ──────────────────────────────────────────────────────────────
-- 2. NOTIFICATION SETTINGS
-- Stores per-user notification preferences & quiet hours.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notification_settings (
    user_id       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    push_enabled  BOOLEAN NOT NULL DEFAULT true,
    email_enabled BOOLEAN NOT NULL DEFAULT false,
    sms_enabled   BOOLEAN NOT NULL DEFAULT false,
    quiet_from    TIME DEFAULT '22:00',
    quiet_to      TIME DEFAULT '07:00',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notification settings"
    ON public.notification_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification settings"
    ON public.notification_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification settings"
    ON public.notification_settings FOR UPDATE
    USING (auth.uid() = user_id);


-- ──────────────────────────────────────────────────────────────
-- 3. CATEGORIES
-- Predefined + user-customizable expense/income categories.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    icon       TEXT NOT NULL DEFAULT 'category',  -- Maps to Flutter Icons name
    color      TEXT NOT NULL DEFAULT '#3D5AFE',    -- Hex color
    type       TEXT NOT NULL DEFAULT 'expense' CHECK (type IN ('income', 'expense')),
    is_default BOOLEAN NOT NULL DEFAULT false,
    user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,  -- NULL for defaults
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Everyone can read default categories; users can read their own custom ones
CREATE POLICY "Anyone can view default categories"
    ON public.categories FOR SELECT
    USING (is_default = true);

CREATE POLICY "Users can view their own categories"
    ON public.categories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own categories"
    ON public.categories FOR INSERT
    WITH CHECK (auth.uid() = user_id AND is_default = false);

CREATE POLICY "Users can update their own categories"
    ON public.categories FOR UPDATE
    USING (auth.uid() = user_id AND is_default = false);

CREATE POLICY "Users can delete their own categories"
    ON public.categories FOR DELETE
    USING (auth.uid() = user_id AND is_default = false);

-- Seed default categories
INSERT INTO public.categories (name, icon, color, type, is_default) VALUES
    ('Groceries',      'shopping_cart',       '#22C55E', 'expense', true),
    ('Transport',      'directions_car',      '#3B82F6', 'expense', true),
    ('Food & Dining',  'restaurant',          '#F97316', 'expense', true),
    ('Entertainment',  'movie',               '#A855F7', 'expense', true),
    ('Bills & Utilities', 'bolt',             '#EF4444', 'expense', true),
    ('Shopping',       'shopping_bag',        '#EC4899', 'expense', true),
    ('Health',         'local_hospital',      '#14B8A6', 'expense', true),
    ('Education',      'school',              '#6366F1', 'expense', true),
    ('Salary',         'account_balance',     '#22C55E', 'income',  true),
    ('Freelance',      'laptop_mac',          '#3B82F6', 'income',  true),
    ('Investment',     'trending_up',         '#F59E0B', 'income',  true),
    ('Other Income',   'attach_money',        '#8B5CF6', 'income',  true);


-- ──────────────────────────────────────────────────────────────
-- 4. EXPENSES (& INCOME TRANSACTIONS)
-- Core financial transaction records.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.expenses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id INT  NOT NULL REFERENCES public.categories(id),
    amount      DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    type        TEXT NOT NULL DEFAULT 'expense' CHECK (type IN ('income', 'expense')),
    description TEXT,
    date        DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast user-scoped queries
CREATE INDEX IF NOT EXISTS idx_expenses_user_date
    ON public.expenses (user_id, date DESC);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own expenses"
    ON public.expenses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own expenses"
    ON public.expenses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own expenses"
    ON public.expenses FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own expenses"
    ON public.expenses FOR DELETE
    USING (auth.uid() = user_id);


-- ──────────────────────────────────────────────────────────────
-- 5. HELPER VIEWS (optional, for dashboard queries)
-- ──────────────────────────────────────────────────────────────

-- Weekly expense summary for the current user
CREATE OR REPLACE VIEW public.weekly_expense_summary AS
SELECT
    user_id,
    date,
    EXTRACT(DOW FROM date) AS day_of_week,
    SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS total_expense,
    SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END) AS total_income
FROM public.expenses
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY user_id, date
ORDER BY date;
