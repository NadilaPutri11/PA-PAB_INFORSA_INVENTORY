import 'peminjaman_model.dart';

class PengembalianModel {
  final String id;
  final String peminjamanId;
  final DateTime? tanggalDikembalikan;
  final String? fotoKembaliDepanUrl;
  final String? fotoKembaliBelakangUrl;
  final String? catatanPengembalian;
  final String status;
  final DateTime? createdAt;
  final PeminjamanModel? peminjaman;

  PengembalianModel({
    required this.id,
    required this.peminjamanId,
    this.tanggalDikembalikan,
    this.fotoKembaliDepanUrl,
    this.fotoKembaliBelakangUrl,
    this.catatanPengembalian,
    this.status = 'menunggu_konfirmasi',
    this.createdAt,
    this.peminjaman,
  });

  factory PengembalianModel.fromMap(Map<String, dynamic> map) {
    return PengembalianModel(
      id: map['id'] ?? '',
      peminjamanId: map['peminjaman_id'] ?? '',
      tanggalDikembalikan: map['tanggal_dikembalikan'] != null
          ? DateTime.parse(map['tanggal_dikembalikan'])
          : null,
      fotoKembaliDepanUrl: map['foto_kembali_depan_url'],
      fotoKembaliBelakangUrl: map['foto_kembali_belakang_url'],
      catatanPengembalian: map['catatan_pengembalian'],
      status: map['status'] ?? 'menunggu_konfirmasi',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      peminjaman: map['peminjaman'] != null
          ? PeminjamanModel.fromMap(map['peminjaman'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'peminjaman_id': peminjamanId,
      'tanggal_dikembalikan': tanggalDikembalikan?.toIso8601String(),
      'foto_kembali_depan_url': fotoKembaliDepanUrl,
      'foto_kembali_belakang_url': fotoKembaliBelakangUrl,
      'catatan_pengembalian': catatanPengembalian,
      'status': status,
    };
  }

  PengembalianModel copyWith({
    String? peminjamanId,
    DateTime? tanggalDikembalikan,
    String? fotoKembaliDepanUrl,
    String? fotoKembaliBelakangUrl,
    String? catatanPengembalian,
    String? status,
    DateTime? createdAt,
    PeminjamanModel? peminjaman,
  }) {
    return PengembalianModel(
      id: id,
      peminjamanId: peminjamanId ?? this.peminjamanId,
      tanggalDikembalikan: tanggalDikembalikan ?? this.tanggalDikembalikan,
      fotoKembaliDepanUrl: fotoKembaliDepanUrl ?? this.fotoKembaliDepanUrl,
      fotoKembaliBelakangUrl:
          fotoKembaliBelakangUrl ?? this.fotoKembaliBelakangUrl,
      catatanPengembalian: catatanPengembalian ?? this.catatanPengembalian,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      peminjaman: peminjaman ?? this.peminjaman,
    );
  }
}
