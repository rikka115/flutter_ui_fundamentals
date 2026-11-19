# Course Data Manager (Pertemuan 7)

Aplikasi Flutter Course Data Manager yang mengintegrasikan REST API, Backend Service, dan Database Supabase dengan arsitektur terstruktur (Model → DataSource/Service → Repository → Provider → UI).

## Identitas Mahasiswa
- **Nama**: Kadek Rica Cahyani
- **NIM**: 2415051026
- **Kelas**: 5 IKI PTI

---

## Tahap 11: Schema Database Supabase (`courses`)

Tabel `courses` dibuat pada Supabase PostgreSQL dengan struktur sebagai berikut:

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `bigint` (Identity) | Primary Key, Auto Increment |
| `code` | `text` | Kode unik mata kuliah (misal: `MOB01`) |
| `title` | `text` | Nama mata kuliah |
| `credits` | `int` | Jumlah SKS (misal: `3`) |
| `status` | `text` | Status (`planned`, `active`, `done`) |
| `created_at` | `timestamptz` | Waktu pembuatan baris data |

### SQL DDL & RLS Policy
Script SQL lengkap tersedia di file [`supabase_schema.sql`](supabase_schema.sql).
Policy RLS yang digunakan pada praktikum laboratorium ini mengizinkan operasi SELECT, INSERT, UPDATE, dan DELETE secara publik melalui client anon key.
