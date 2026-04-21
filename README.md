# PA-PAB_INFORSA_INVENTORY

## Anggota Kelompok

| Nama                     |        NIM |
| :----------------------- | ---------: |
| Dinda Aulia Rizky        | 2409116076 |
| Nadila Putri             | 2409116052 |
| Syawe Manisha P. Siregar | 2409116058 |
| Azhaar Athahiroh         | 2409116057 |

---

# INFORSA INVENTORY

Aplikasi **Inforsa Inventory** adalah sistem digital untuk membantu pengelolaan inventaris barang pada Department Bureau of Entrepreneurship Development di organisasi INFORSA. Aplikasi ini dibuat untuk merapikan proses pencatatan barang, peminjaman, pengembalian, dan pertanggungjawaban penggunaan inventaris.

Melalui aplikasi ini, proses peminjaman dapat dilakukan secara sistematis dengan pencatatan status peminjaman, batas waktu pengembalian, identitas peminjam, serta unggahan foto kondisi barang sebelum dan sesudah digunakan. Aplikasi juga menyediakan riwayat aktivitas agar setiap transaksi tercatat dengan jelas dan akuntabel.

---

# Fitur Aplikasi

Fitur utama pada aplikasi dibagi berdasarkan peran pengguna agar pengelolaan inventaris dan alur peminjaman berjalan lebih tertib.

### 1. Login dan Role

Terdapat dua peran utama, yaitu admin dan user. Admin memiliki akses penuh terhadap pengelolaan data inventaris, sedangkan user berfokus pada operasional peminjaman.

### 2. Kelola Barang (Admin)

Admin dapat menambah, mengedit, dan menghapus data barang. Fitur ini terhubung dengan Supabase Storage untuk penyimpanan foto barang dan dokumen nota.

### 3. Katalog Inventaris (User)

User dapat melihat daftar inventaris yang tersedia, stok barang, serta detail spesifikasi dan kondisi sebelum mengajukan peminjaman.

### 4. Peminjaman, Perpanjangan, dan Pengembalian

User dapat mengajukan peminjaman barang, memperpanjang masa pinjam, dan memulai proses pengembalian dengan mengunggah bukti kondisi barang.

### 5. Approval (Admin)

Admin dapat meninjau pengajuan peminjaman, perpanjangan, dan pengembalian sebelum memberikan persetujuan atau penolakan.

### 6. Notifikasi

Sistem memberikan notifikasi terkait perubahan status pengajuan dan pengingat jatuh tempo peminjaman.

### 7. Profil dan Riwayat Aktivitas

User dapat mengelola profil, melihat riwayat aktivitas, dan mengakses kontak bantuan melalui integrasi WhatsApp admin.

---

# Struktur Folder

Project ini disusun dengan pendekatan feature-based agar pemisahan model, provider, service, page, dan widget tetap jelas.

```text
lib/
|-- models/       # Struktur data utama
|-- pages/        # Halaman UI admin, auth, dan user
|-- providers/    # State management dan business logic
|-- services/     # Integrasi Supabase
|-- utils/        # Helper utilitas lintas platform
|-- widgets/      # Reusable widgets
`-- main.dart     # Entry point aplikasi
```

---

# Package Tambahan (Dependencies)

Bagian ini diperbarui berdasarkan isi `pubspec.yaml` dan pemakaian aktual di folder `lib/` serta `test/`.

## Package yang dipakai langsung di source code

- **`supabase_flutter`** (^2.12.4) - Dipakai untuk database, autentikasi, realtime update, dan storage melalui Supabase.
- **`flutter_dotenv`** (^6.0.0) - Memuat konfigurasi sensitif dari `assets/.env` saat aplikasi dijalankan.
- **`provider`** (^6.1.1) - Menangani state management melalui `ChangeNotifierProvider`, `context.read`, dan `context.watch`.
- **`intl`** (^0.20.2) - Dipakai untuk format tanggal, locale Indonesia, dan format angka atau harga.
- **`file_picker`** (^11.0.2) - Dipakai saat upload foto barang, bukti kondisi, dan dokumen nota.
- **`url_launcher`** (^6.3.1) - Dipakai untuk membuka tautan eksternal seperti kontak WhatsApp admin.
- **`responsive_builder`** (^0.7.1) - Dipakai di dashboard admin untuk membedakan layout mobile, tablet, dan desktop.
- **`data_table_2`** (^2.7.2) - Dipakai untuk tabel data di dashboard admin dan dashboard user.
- **`excel`** (^4.0.6) - Dipakai untuk ekspor data dashboard admin ke format Excel.
- **`csv`** (^8.0.0) - Dipakai untuk ekspor data dashboard admin ke format CSV.
- **`path_provider`** (^2.1.5) - Dipakai untuk menentukan lokasi penyimpanan file hasil ekspor di device non-web.
- **`open_filex`** (^4.7.0) - Dipakai untuk membuka file hasil ekspor setelah berhasil dibuat.
- **`flutter_test`** (SDK) - Dipakai pada `test/dashboard_test.dart` untuk unit test sederhana provider dashboard.

## Package yang masih tercantum di `pubspec.yaml` tetapi belum terlihat dipakai langsung

- **`cached_network_image`** (^3.3.1) - Belum ditemukan pemakaian; gambar remote saat ini masih menggunakan `Image.network`.
- **`fl_chart`** (^1.2.0) - Belum ditemukan import atau widget chart yang aktif dipakai.
- **`rxdart`** (^0.28.0) - Belum ditemukan pemakaian; debounce yang ada masih memakai `Timer` dari Dart.
- **`cupertino_icons`** (^1.0.2) - Belum ditemukan pemanggilan `CupertinoIcons` pada source code saat ini.
- **`mockito`** (^5.6.4) - Sudah terpasang di `dev_dependencies`, tetapi belum dipakai pada file test yang ada.
- **`test`** (^1.26.3) - Sudah terpasang di `dev_dependencies`, tetapi pengujian saat ini memakai `flutter_test`.
- **`flutter_lints`** (^6.0.0) - Dipakai sebagai aturan linting project, bukan package runtime aplikasi.

---

# Widget yang Digunakan

Berikut adalah widget Flutter yang benar-benar muncul di source code project ini, dikelompokkan berdasarkan perannya di UI.

## 1. Struktur aplikasi dan navigasi

- `MaterialApp`, `Scaffold`, `SafeArea`, `AppBar`, `DefaultTabController`, `TabBar`, `TabBarView`
- `BottomNavigationBar`, `BottomNavigationBarItem`, `Navigator`, `MaterialPageRoute`

## 2. Layout dan pembungkus konten

- `Container`, `Padding`, `SizedBox`, `Column`, `Row`, `Expanded`, `Center`, `Stack`, `Positioned`, `Wrap`
- `SingleChildScrollView`, `ListView.builder`, `ListView.separated`, `GridView.count`, `ExpansionTile`

## 3. Form dan interaksi pengguna

- `TextField`, `TextFormField`, `DropdownButtonFormField`, `DropdownButton`, `DropdownMenuItem`
- `PopupMenuButton`, `PopupMenuItem`, `IconButton`, `ElevatedButton`, `ElevatedButton.icon`
- `OutlinedButton`, `OutlinedButton.icon`, `TextButton`, `GestureDetector`, `InkWell`, `showDatePicker`

## 4. Penyajian data dan elemen visual

- `Text`, `Icon`, `Image.asset`, `Image.network`, `CircleAvatar`, `Badge`
- `DataTable2`, `DataColumn2`, `DataRow`, `DataCell`, `RichText`, `TextSpan`, `ListTile`

## 5. Feedback dan dialog

- `AlertDialog`, `showDialog`, `SnackBar`, `CircularProgressIndicator`

## 6. Responsive dan custom widget project

- **`ScreenTypeLayout.builder`** - Dipakai pada dashboard admin agar layout menyesuaikan ukuran layar
- **`SplashScreen`** - Halaman awal untuk cek session dan menentukan routing awal pengguna
- **`InforsaHeader`** - App bar reusable dengan logo dan indikator notifikasi
- **`AdminNavbar`** - Bottom navigation khusus admin dengan badge approval
- **`UserNavbar`** - Bottom navigation khusus user
- **`FilterRowWidget`**, **`CustomDropdown`**, **`AdminPagination`**, **`AdminAssetCard`** - Widget bantu di halaman inventaris admin
- **`AprPeminjamanTab`**, **`AprPerpanjanganTab`**, **`AprPengembalianTab`** - Widget tab approval admin untuk tiap jenis pengajuan

---

# Skema Database (Supabase)

Berikut adalah rancangan tabel utama yang digunakan di database Supabase.

### 1. Tabel `users`

Menyimpan data profil pengguna dan admin.

- `id` (UUID, Primary Key)
- `nama` (Text)
- `departemen` (Text)
- `nim` (Text, Nullable)
- `no_whatsapp` (Text, Nullable)
- `avatar_url` (Text, Nullable)
- `created_at` (Timestamp)

### 2. Tabel `barang`

Menyimpan master data inventaris barang.

- `id` (UUID, Primary Key)
- `kode_barang` (Text)
- `nama_barang` (Text)
- `volume` (Integer)
- `tersedia` (Integer, Nullable)
- `satuan` (Text)
- `asal_barang` (Text)
- `kondisi_barang` (Text)
- `spesifikasi_barang` (Text, Nullable)
- `tahun_pembuatan` (Integer, Nullable)
- `harga_barang` (Numeric, Nullable)
- `dokumen_nota_url` (Text, Nullable)
- `foto_url` (Text, Nullable)
- `keterangan_tambahan` (Text, Nullable)
- `tanggal_pembukuan` (Timestamp, Nullable)
- `created_at` (Timestamp)

### 3. Tabel `peminjaman`

Menyimpan transaksi peminjaman barang oleh user.

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key ke `users.id`)
- `barang_id` (UUID, Foreign Key ke `barang.id`)
- `tanggal_pinjam` (Timestamp)
- `rencana_kembali` (Timestamp)
- `alasan_meminjam` (Text, Nullable)
- `foto_sebelum_pinjam_url` (Text, Nullable)
- `status` (Text) - `menunggu`, `disetujui`, `ditolak`, `selesai`, `dibatalkan`
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

### 4. Tabel `perpanjangan`

Menyimpan pengajuan perpanjangan waktu peminjaman.

- `id` (UUID, Primary Key)
- `peminjaman_id` (UUID, Foreign Key ke `peminjaman.id`)
- `tanggal_jatuh_tempo_baru` (Timestamp)
- `alasan_perpanjangan` (Text, Nullable)
- `status` (Text)
- `created_at` (Timestamp)

### 5. Tabel `pengembalian`

Menyimpan data pengembalian barang beserta bukti foto kondisi barang.

- `id` (UUID, Primary Key)
- `peminjaman_id` (UUID, Foreign Key ke `peminjaman.id`)
- `tanggal_dikembalikan` (Timestamp, Nullable)
- `foto_kembali_depan_url` (Text, Nullable)
- `foto_kembali_belakang_url` (Text, Nullable)
- `catatan_pengembalian` (Text, Nullable)
- `status` (Text)
- `created_at` (Timestamp)

### 6. Tabel `notifications`

Menyimpan riwayat notifikasi untuk masing-masing user.

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key ke `users.id`)
- `title` (Text)
- `message` (Text)
- `is_read` (Boolean, Default: false)
- `type` (Text, Nullable)
- `created_at` (Timestamp)

---
