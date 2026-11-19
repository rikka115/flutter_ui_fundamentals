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
