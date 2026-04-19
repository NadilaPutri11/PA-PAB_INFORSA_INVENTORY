class PeminjamanModel {
  final String id;
  final String userId;
  final String barangId;
  final DateTime tanggalPinjam;
  final DateTime rencanakembali;
  final String? alasanMeminjam;
  final String? fotoSebelumPinjamUrl;
  final String status;
  final DateTime? createdAt;
  // FIX: Tambahkan baris ini
  final DateTime? updatedAt;

  // Data join
  final String? namaBarang;
  final String? kodeBarang;
  final String? namaUser;
  final String? departemenUser;

  PeminjamanModel({
    required this.id,
    required this.userId,
    required this.barangId,
    required this.tanggalPinjam,
    required this.rencanakembali,
    this.alasanMeminjam,
    this.fotoSebelumPinjamUrl,
    required this.status,
    this.createdAt,
    // FIX: Tambahkan di constructor
    this.updatedAt,
    this.namaBarang,
    this.kodeBarang,
    this.namaUser,
    this.departemenUser,
  });

  bool get isMenunggu => status == 'menunggu';
  bool get isDisetujui => status == 'disetujui';
  bool get isDitolak => status == 'ditolak';
  bool get isSelesai => status == 'selesai';
  bool get isBatalkan => status == 'dibatalkan';
  bool get isMenungguKonfirmasi => status == 'menunggu_konfirmasi';

  bool get isTerlambat => isDisetujui && DateTime.now().isAfter(rencanakembali);

  int get sisaHari => rencanakembali.difference(DateTime.now()).inDays;

  factory PeminjamanModel.fromMap(Map<String, dynamic> map) {
    return PeminjamanModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      barangId: map['barang_id'] ?? '',
      tanggalPinjam: map['tanggal_pinjam'] != null
          ? DateTime.parse(map['tanggal_pinjam'])
          : DateTime.now(),
      rencanakembali: map['rencana_kembali'] != null
          ? DateTime.parse(map['rencana_kembali'])
          : DateTime.now(),
      alasanMeminjam: map['alasan_meminjam'],
      fotoSebelumPinjamUrl: map['foto_sebelum_pinjam_url'],
      status: map['status'] ?? 'menunggu',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      // FIX: Tambahkan parsing dari database (Supabase otomatis pakai nama updated_at)
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      namaBarang: map['barang'] != null ? map['barang']['nama_barang'] : null,
      kodeBarang: map['barang'] != null ? map['barang']['kode_barang'] : null,
      namaUser: map['users'] != null ? map['users']['nama'] : null,
      departemenUser: map['users'] != null ? map['users']['departemen'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'barang_id': barangId,
      'tanggal_pinjam': tanggalPinjam.toIso8601String(),
      'rencana_kembali': rencanakembali.toIso8601String(),
      'alasan_meminjam': alasanMeminjam,
      'foto_sebelum_pinjam_url': fotoSebelumPinjamUrl,
      'status': status,
    };
  }

  PeminjamanModel copyWith({
    String? id,
    String? userId,
    String? barangId,
    DateTime? tanggalPinjam,
    DateTime? rencanakembali,
    String? alasanMeminjam,
    String? fotoSebelumPinjamUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? namaBarang,
    String? kodeBarang,
    String? namaUser,
    String? departemenUser,
  }) {
    return PeminjamanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      barangId: barangId ?? this.barangId,
      tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
      rencanakembali: rencanakembali ?? this.rencanakembali,
      alasanMeminjam: alasanMeminjam ?? this.alasanMeminjam,
      fotoSebelumPinjamUrl: fotoSebelumPinjamUrl ?? this.fotoSebelumPinjamUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      namaBarang: namaBarang ?? this.namaBarang,
      kodeBarang: kodeBarang ?? this.kodeBarang,
      namaUser: namaUser ?? this.namaUser,
      departemenUser: departemenUser ?? this.departemenUser,
    );
  }
}

