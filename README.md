# Course Data Manager (Pertemuan 7)
## RESTful API, Backend Services & Database Integration

Aplikasi Flutter **Course Data Manager** (pengembangan lanjutan dari Course Explorer v2) yang menghubungkan aplikasi dengan layanan REST API, Backend Service, dan Database Supabase PostgreSQL secara terstruktur.

---

### Identitas Mahasiswa
- **Nama**: Kadek Rica Cahyani
- **NIM**: 2415051026
- **Kelas**: 5 IKI PTI
- **Dosen Pengampu**: Dr. Ir. I Ketut Resika Arthana, S.T., M.Kom.
- **Teaching Assistant**: Made Yuda Sadewa, S.Pd.
- **Repository GitHub**: [https://github.com/rikka115/flutter_ui_fundamentals](https://github.com/rikka115/flutter_ui_fundamentals)

---

### Fitur Utama Aplikasi
1. **CRUD Terintegrasi (Create, Read, Update, Delete)**:
   - **Read / SELECT**: Membaca daftar course dari backend/database secara asynchronous.
   - **Create / POST / INSERT**: Formulir penambahan mata kuliah baru dengan validasi field wajib dan tipe data SKS.
   - **Update / PUT / UPDATE**: Edit data mata kuliah dari halaman detail dengan kode mata kuliah read-only (sebagai identifier konsistensi).
   - **Delete / DELETE**: Penghapusan data dengan modal dialog konfirmasi serta otomatis menghapus dari daftar favorit agar tidak terjadi data yatim.
2. **State Management & Async UI State**:
   - Explicit state handling: **Loading State** (Progress indicator), **Success State** (Grid/List courses), **Empty State** (Pesan data kosong), dan **Error State** (Error message + tombol Retry).
   - Guard submit ganda (`isSaving`) dan penanganan `mounted` context yang aman setelah operasi asynchronous.
3. **Repository Pattern & Clean Architecture**:
   - Pemisahan tanggung jawab (*Separation of Concerns*) secara ketat:
     - **Model**: `Course` dengan serialisasi `fromJson()` dan `toJson()`.
     - **Data Source / Service**: Kontrak abstrak `CourseDataSource` yang diimplementasikan oleh `CourseApiService` (REST API) dan `CourseSupabaseService` (Supabase Client).
     - **Repository**: `CourseRepository` sebagai perantara abstraksi akses data bagi provider.
     - **State / Provider**: `CourseProvider` mengelola state data, loading, error, dan sinkronisasi daftar favorit.
     - **Presentation / UI**: Screen dan Widget terpisah (`ResponsiveShell`, `CourseListPage`, `CourseDetailPage`, `CourseFormPage`, `FavoritesPage`, `CourseCard`, `ErrorView`).
4. **Fleksibilitas Pergantian Backend**:
   - Pergantian sumber data antara REST API dan Supabase Database dapat dilakukan hanya dengan mengubah satu baris deklarasi `CourseDataSource` pada `lib/main.dart` tanpa menyentuh UI maupun Provider.
5. **Responsive Layout & Navigation**:
   - Navigasi adaptif menggunakan `NavigationBar` pada layar compact (ponsel) dan `NavigationRail` pada layar medium/expanded (tablet/desktop).
   - Layar detail course yang menerima objek data via constructor serta fitur Favorit yang tersinkronisasi lintas halaman.

---

### Struktur Proyek

```
lib/
├── config/
│   └── supabase_config.dart          # Konfigurasi URL dan publishable/anon key Supabase
├── models/
│   └── course.dart                   # Data model Course (fromJson & toJson)
├── services/
│   ├── course_data_source.dart       # Abstract interface kontrak sumber data
│   ├── course_api_service.dart       # Implementasi REST API HTTP Client
│   └── course_supabase_service.dart  # Implementasi Supabase Client SDK
├── repositories/
│   └── course_repository.dart        # Repository layer untuk abstraksi data
├── providers/
│   └── course_provider.dart          # State management (ChangeNotifier)
├── screens/
│   ├── responsive_shell.dart         # Layout wrapper adaptif (NavigationBar / Rail)
│   ├── course_list_page.dart         # Daftar course, empty, loading, delete, refresh
│   ├── course_detail_page.dart       # Halaman detail course & aksi edit/hapus/favorit
│   ├── course_form_page.dart         # Form tambah dan edit course dengan validasi
│   └── favorites_page.dart           # Halaman daftar course favorit
├── widgets/
│   ├── course_card.dart              # Komponen kartu course interaktif
│   └── error_view.dart               # Tampilan penanganan error dan tombol retry
└── main.dart                         # Entry point aplikasi & dependency injection
```

---

### Cara Menjalankan Aplikasi

1. **Clone repository**:
   ```bash
   git clone https://github.com/rikka115/flutter_ui_fundamentals.git
   cd flutter_ui_fundamentals
   ```

2. **Pasang dependensi**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Supabase (Opsional jika menggunakan backend Supabase)**:
   - Buat tabel `courses` menggunakan script DDL pada [`supabase_schema.sql`](supabase_schema.sql).
   - Masukkan Project URL dan Anon Key pada `lib/config/supabase_config.dart`.
   - Pilih data source aktif pada `lib/main.dart`:
     ```dart
     final CourseDataSource dataSource = CourseSupabaseService(); // atau CourseApiService(baseUrl)
     ```

4. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```

---

### Riwayat Commit Praktikum (Pertemuan 7)

| Tahap | Hash Commit | Pesan Commit |
|---|---|---|
| **0** | `79ac27b` | Siapkan project untuk integrasi REST API |
| **1** | `79ac27b` | Dokumentasikan endpoint REST dan struktur JSON |
| **2** | `4bb1463` | Implementasikan HTTP GET dan parsing response |
| **3** | `2259aa6` | Tambahkan model Course dan JSON mapping |
| **4** | `a5833f1` | Pisahkan akses REST API ke service layer |
| **5** | `c2135d8` | Tambahkan loading empty error dan retry state |
| **6** | `1b85981` | Tambahkan create course melalui HTTP POST |
| **7** | `97fe679` | Tambahkan update course melalui HTTP PUT atau PATCH |
| **8** | `e5f8c87` | Tambahkan delete course melalui HTTP DELETE |
| **9** | `db52858` | Refactor REST access menggunakan repository pattern |
| **10** | `788145a` | Konfigurasikan Supabase client untuk backend database |
| **11** | `c5ffb12` | Dokumentasikan schema database Supabase |
| **12** | `4bfb984` | Baca data courses dari Supabase database |
| **13** | `cd23696` | Tambahkan insert course ke Supabase |
| **14** | `c42b04c` | Tambahkan update course di Supabase |
| **15** | `cab26c9` | Tambahkan delete course di Supabase |
| **16** | `7bf0dd5` | Selesaikan Course Data Manager CRUD terintegrasi |
| **17** | `5b4b024` | Tambahkan error handling dan security hardening dasar |
| **18** | *(Final)* | Finalisasi README dan bukti pengumpulan pertemuan 7 |
