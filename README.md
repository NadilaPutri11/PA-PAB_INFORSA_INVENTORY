# PA-PAB_INFORSA_INVENTORY

## Anggota Kelompok

| Nama                     |        NIM |
| :----------------------- | ---------: |
| Dinda Aulia Rizky        | 2409116076 |
| Nadila Putri             | 2409116052 |
| Syawe Manisha P. Siregar | 2409116058 |
| Azhaar Athahiroh         | 2409116057 |

---

# INFORSA INVENTORY ᯓᡣ𐭩

Aplikasi **Inforsa Inventory** merupakan sistem berbasis digital yang dirancang untuk membantu pengelolaan inventaris barang pada Department Bureau of Entrepreneurship Development di organisasi INFORSA. Aplikasi ini dibuat untuk mengatasi permasalahan dalam pencatatan barang, peminjaman, serta pertanggungjawaban penggunaan inventaris yang sebelumnya belum terstruktur dengan baik.

Melalui aplikasi ini, proses peminjaman barang dapat dilakukan secara sistematis dengan adanya pencatatan status peminjaman, batas waktu pengembalian, serta identitas peminjam. Selain itu, aplikasi ini juga menyediakan fitur dokumentasi kondisi barang melalui unggahan foto sebelum dan sesudah peminjaman, sehingga kondisi barang dapat dipantau dengan lebih transparan.

Inforsa Inventory juga dilengkapi dengan sistem pencatatan riwayat aktivitas yang memungkinkan setiap transaksi tercatat dengan jelas. Hal ini bertujuan untuk meningkatkan akuntabilitas dan meminimalisir risiko kehilangan atau kerusakan barang tanpa tanggung jawab yang jelas.

Dengan adanya aplikasi ini, diharapkan pengelolaan inventaris dalam organisasi dapat menjadi lebih efisien, terorganisir, serta mudah diakses oleh pengguna yang berwenang.

---

# ꫂ❁ Fitur Aplikasi

Di dalam aplikasi INFORSA, terdapat beberapa fitur utama yang dirancang untuk memudahkan manajemen aset secara digital. Fitur-fitur ini dibagi berdasarkan hak akses pengguna agar proses inventarisasi dan peminjaman berjalan lebih tertib:

### **1. Login & Role**

=> Terdapat Admin dan User biasa. Fitur ini membatasi hak akses pengguna berdasarkan peran mereka. Admin memiliki kontrol penuh terhadap manajemen aset, sementara User berfokus pada operasional peminjaman.

### **2. Kelola Barang (Admin)**

=> Pusat kontrol data aset di mana Admin dapat menambah, mengedit, atau menghapus barang. Fitur ini sudah dilengkapi dengan sinkronisasi ke Supabase Storage untuk menyimpan foto barang dan dokumen nota.

### **3. Katalog (User)**

=> Ruang bagi pengguna untuk mengeksplorasi inventaris yang tersedia. User dapat memantau stok secara real-time serta melihat spesifikasi dan kondisi aset sebelum memutuskan untuk meminjam.

### **4. Pinjam Barang**

=> Fitur utama yang memungkinkan User mengajukan permintaan peminjaman dengan lampiran foto kondisi awal. User juga dapat melakukan perpanjangan masa pinjam atau memulai proses pengembalian dengan mengunggah foto kondisi akhir.

### **5. Approval (Admin)**

=> Modul verifikasi bagi Admin untuk meninjau setiap pengajuan dari User. Admin dapat melihat detail alasan peminjaman dan bukti foto sebelum memberikan persetujuan atau penolakan.

### **6. Notifikasi**

=> Memberikan informasi instan kepada User mengenai perubahan status pengajuan mereka (Menunggu, Disetujui, atau Ditolak). Dashboard juga menampilkan pengingat otomatis jika aset sudah mendekati jatuh tempo (H-3).

### **7. Profil**

=> Tempat bagi pengguna untuk mengelola informasi pribadi, memantau riwayat aktivitas secara lengkap, serta akses cepat layanan bantuan melalui integrasi WhatsApp Admin.

---

# ꫂ❁ Struktur Folder

Aplikasi ini disusun menggunakan pola Feature-based architecture agar setiap bagian kodingan tertata rapi sesuai fungsinya masing-masing. Hal ini memudahkan proses pengembangan dan perbaikan jika terjadi kendala pada fitur tertentu:

```text
lib/
├── models/         # Struktur data (ItemModel, UserModel, PeminjamanModel)
├── pages/          # Folder utama yang menampung seluruh tampilan antarmuka (UI)
│   ├── admin/      # Dashboard admin, kelola barang, approval
│   ├── auth/       # Login & register
│   └── user/       # Dashboard user, form pinjam, profil
├── providers/      # Logika Bisnis & pengelolaan status (AuthProvider, InventoryProvider)
├── services/       # Koneksi Supabase
├── widgets/        # kumpulan komponen visual seperti header atau tombol yang didesain agar bisa digunakan berulang kali (InforsaHeader, AdminNavbar)
└── main.dart       # File utama untuk menjalankan aplikasi.
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
- **`flutter_lints`** (^6.0.0) - Dipakai sebagai aturan linting project, bukan package runtime aplikasi.
- **`fl_chart**` digunakan untuk menampilkan grafik pada dashboard aplikasi.
- **`cached_network_image**` digunakan untuk memuat dan menyimpan (cache) gambar barang dari internet.
- **`rxdart**` digunakan untuk mengelola pembaruan data secara realtime.
- **`cupertino_icons**` digunakan untuk menyediakan ikon pada antarmuka aplikasi.
- **`mockito**` digunakan untuk membuat data simulasi saat pengujian.
- **`test`** digunakan untuk melakukan unit testing pada aplikasi.

---

# Widget yang Digunakan

Berikut adalah widget Flutter yang benar-benar muncul di source code project ini, dikelompokkan berdasarkan perannya di UI.

## 1. Struktur Aplikasi & Navigasi
- **MaterialApp** (root aplikasi dan pengaturan tema/routing).
- **Scaffold**, **SafeArea**, **AppBar** (struktur dasar halaman dan header).
- **DefaultTabController**, **TabBar**, **TabBarView** (navigasi berbasis tab).
- **BottomNavigationBar**, **BottomNavigationBarItem** (navigasi menu bawah).
- **Navigator**, **MaterialPageRoute** (perpindahan antar halaman).

## 3. Layout & Pembungkus Konten
- **Container**, **Padding**, **SizedBox** (pengaturan ukuran, jarak dalam, dan styling).
- **Column**, **Row**, **Expanded**, **Center** (pengaturan layout vertikal dan horizontal).
- **Stack**, **Positioned**, **Wrap** (layout fleksibel dan penumpukan widget).
- **SingleChildScrollView**, **ListView.builder**, **ListView.separated** (konten yang dapat di-scroll).
- **GridView.count**, **ExpansionTile** (tampilan grid dan list expandable).
- **Margin** (jarak luar antar elemen, biasanya melalui **Container**).
  
## 4. Form & Interaksi
- **TextField**, **TextFormField** (untuk form login, register, dan input data barang).
- **DropdownButtonFormField**, **DropdownButton**, **DropdownMenuItem** (untuk memilih kategori seperti asal barang, kondisi, dll).
- **ElevatedButton**, **OutlinedButton**, **TextButton** (untuk aksi utama dan sekunder).
- **IconButton**, **GestureDetector**, **InkWell** (untuk interaksi berbasis tap/gesture).
- **PopupMenuButton**, **PopupMenuItem** (untuk menu tambahan seperti edit/hapus).
- **showDatePicker** (untuk memilih tanggal).

## 5. Tampilan Data (Display)
- **Text**, **Icon** (Material Icons & Cupertino).
- **CircleAvatar**, **Badge** (untuk foto profil dan indikator notifikasi).
- **Card**, **ListTile**, **Divider** (untuk menampilkan daftar item, aktivitas, dan riwayat).
- **Image.asset**, **Image.network**, **CachedNetworkImage** (untuk menampilkan gambar lokal dan dari internet).
- **DataTable2**, **DataColumn2**, **DataRow**, **DataCell** (untuk menampilkan data dalam bentuk tabel).
- **RichText**, **TextSpan** (untuk teks dengan berbagai gaya dalam satu baris).
  
## 6. Feedback & Dialog
- **AlertDialog**, **showDialog** (untuk konfirmasi aksi seperti hapus data).
- **SnackBar** (untuk notifikasi sukses atau gagal).
- **CircularProgressIndicator** (indikator loading saat proses data).

## 7. Responsive dan custom widget project

- **`ScreenTypeLayout.builder`** (Dipakai pada dashboard admin agar layout menyesuaikan ukuran layar)
- **`SplashScreen`** (Halaman awal untuk cek session dan menentukan routing awal pengguna)
- **`InforsaHeader`** (App bar reusable dengan logo dan indikator notifikasi)
- **`AdminNavbar`** (Bottom navigation khusus admin dengan badge approval)
- **`UserNavbar`** (Bottom navigation khusus user)
- **`FilterRowWidget`**, **`CustomDropdown`**, **`AdminPagination`**, **`AdminAssetCard`** (Widget bantu di halaman inventaris admin)
- **`AprPeminjamanTab`**, **`AprPerpanjanganTab`**, **`AprPengembalianTab`** (Widget tab approval admin untuk tiap jenis pengajuan)

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
