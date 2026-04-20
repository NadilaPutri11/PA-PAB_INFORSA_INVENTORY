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

# ꫂ❁ Package Tambahan (Dependencies)

Untuk memaksimalkan fungsi dan keamanan aplikasi, digunakan beberapa pustaka (package) tambahan sebagai berikut:

- **`supabase_flutter`** (^2.12.4) - Menghubungkan aplikasi dengan database, autentikasi, dan penyimpanan berkas foto/nota secara real-time.
  
- **`provider`** (^6.1.1) - Mengelola logika bisnis dan sinkronisasi status data di seluruh halaman aplikasi.
  
- **`flutter_dotenv`** (^6.0.0) - Melindungi kredensial sensitif seperti kunci API dan URL server agar tidak terekspos dalam kode.
  
- **`intl`** (^0.20.2) - Menstandarisasi format tanggal pengembalian dan tampilan angka mata uang sesuai bahasa Indonesia.
  
- **`cached_network_image`** (^3.3.1) - Mengoptimalkan pemuatan gambar dari server dengan sistem penyimpanan memori sementara (cache).
  
- **`file_picker`** (^11.0.2) - Menyediakan antarmuka untuk memilih berkas foto barang atau dokumen nota dari perangkat pengguna.
  
- **`url_launcher`** (^6.3.0) - Memungkinkan aplikasi membuka tautan eksternal seperti WhatsApp Admin atau peramban web.
  
- **`cupertino_icons`** (^1.0.2) - Menyediakan kumpulan ikon standar iOS untuk memperkaya estetika antarmuka aplikasi.

---

# ꫂ❁ Widget yang Digunakan

Widget adalah komponen dasar dalam Flutter yang digunakan untuk membangun tampilan dan struktur aplikasi. Berikut adalah beberapa widget yang digunakan di dalam membuat aplikasi ini:

## 1. Layout & Struktur

- `Scaffold`, `AppBar`, `Container`, `Column`, `Row`, `Stack`, `Expanded`, `Padding`, `Margin`.
- `SingleChildScrollView`, `ListView`, `GridView` (untuk konten yang dapat di-scroll).

## 2. Input & Interaksi

- `TextField`, `TextFormField` (untuk form login, register, dan data barang).
- `ElevatedButton`, `TextButton`, `IconButton`, `GestureDetector`, `InkWell` (untuk tombol dan aksi tap).
- `DropdownButtonFormField` (untuk memilih asal barang, kondisi, departemen, dll).

### 3. Tampilan Data (Display)

- `Text`, `Icon` (Material Icons & Cupertino).
- `CircleAvatar` (untuk foto profil pengguna).
- `Card`, `ListTile`, `Divider` (untuk menampilkan daftar item, aktivitas, dan riwayat).
- `Image.network` & `CachedNetworkImage` (untuk menampilkan foto barang).

### 4. Feedback & Dialog

- `AlertDialog`, `showDialog` (untuk konfirmasi aksi seperti hapus barang atau ubah password).
- `SnackBar` (untuk menampilkan pesan sukses/gagal di bagian bawah layar).
- `CircularProgressIndicator` (indikator loading saat mengambil atau mengirim data ke Supabase).

### 5. Custom Widgets

- **`InforsaHeader`**: Header/AppBar khusus dengan logo dan ikon notifikasi yang konsisten.
- **`AdminNavbar`**: Navigasi khusus untuk kemudahan akses menu admin.

---

# ꫂ❁ Skema Database (Supabase)

Berikut adalah rancangan tabel dan relasi pada database Supabase:

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
- `status` (Text) - _menunggu, disetujui, ditolak, selesai, dibatalkan_
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
