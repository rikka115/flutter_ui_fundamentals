-- Schema Database Supabase untuk Course Data Manager (Pertemuan 7)
-- Mahasiswa: Kadek Rica Cahyani (NIM: 2415051026)

-- 1. Buat tabel courses
CREATE TABLE IF NOT EXISTS courses (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  code TEXT NOT NULL,
  title TEXT NOT NULL,
  credits INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'done')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Aktifkan Row Level Security (RLS)
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- 3. Policy Permisif untuk lingkungan praktikum/laboratorium:
-- PERINGATAN KEAMANAN: Policy ini mengizinkan akses anonim (anon key) untuk keperluan praktikum.
-- Pada aplikasi produksi, gunakan kebijakan otentikasi (authenticated) berbasis user ID.
CREATE POLICY "Allow public read access" ON courses
  FOR SELECT USING (true);

CREATE POLICY "Allow public insert access" ON courses
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public update access" ON courses
  FOR UPDATE USING (true);

CREATE POLICY "Allow public delete access" ON courses
  FOR DELETE USING (true);

-- 4. Data awal (minimal 3 data)
INSERT INTO courses (code, title, credits, status) VALUES
  ('MOB01', 'Git & GitHub', 2, 'done'),
  ('MOB02', 'Dart Fundamentals', 2, 'done'),
  ('MOB03', 'Flutter UI', 3, 'active'),
  ('MOB04', 'REST API & Supabase', 3, 'planned');

-- Worksheet 9: Authentication, role, RLS, dan device registration
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'seeker'
    CHECK (role IN ('seeker', 'owner', 'admin'))
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own"
  ON public.profiles FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    CASE
      WHEN NEW.raw_user_meta_data->>'role' IN ('seeker', 'owner')
        THEN NEW.raw_user_meta_data->>'role'
      ELSE 'seeker'
    END
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

INSERT INTO public.profiles (id, email, name, role)
SELECT id, email, '', 'seeker'
FROM auth.users
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.kos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  price INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.kos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kos_select_authenticated" ON public.kos;
CREATE POLICY "kos_select_authenticated"
  ON public.kos FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "kos_insert_owner" ON public.kos;
CREATE POLICY "kos_insert_owner"
  ON public.kos FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = owner_id
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('owner', 'admin')
    )
  );

DROP POLICY IF EXISTS "kos_update_own" ON public.kos;
CREATE POLICY "kos_update_own"
  ON public.kos FOR UPDATE TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "kos_delete_own" ON public.kos;
CREATE POLICY "kos_delete_own"
  ON public.kos FOR DELETE TO authenticated
  USING (auth.uid() = owner_id);

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

DROP POLICY IF EXISTS "kos_admin_all" ON public.kos;
CREATE POLICY "kos_admin_all"
  ON public.kos FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TABLE IF NOT EXISTS public.device_tokens (
  token TEXT PRIMARY KEY,
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  platform TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tokens_select_own" ON public.device_tokens;
CREATE POLICY "tokens_select_own"
  ON public.device_tokens FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "tokens_insert_own" ON public.device_tokens;
CREATE POLICY "tokens_insert_own"
  ON public.device_tokens FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "tokens_update_own" ON public.device_tokens;
CREATE POLICY "tokens_update_own"
  ON public.device_tokens FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "tokens_delete_own" ON public.device_tokens;
CREATE POLICY "tokens_delete_own"
  ON public.device_tokens FOR DELETE TO authenticated
  USING (auth.uid() = user_id);
