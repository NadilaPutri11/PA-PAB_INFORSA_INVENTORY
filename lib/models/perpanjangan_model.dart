import 'peminjaman_model.dart';

class PerpanjanganModel {
  final String id;
  // FIX: Rename peminjamamId → peminjamanId
  final String peminjamanId;
  final DateTime tanggalJatuhTempoBaru;
  final String? alasanPerpanjangan;
  // FIX: Tambah field status
  final String status;
  final DateTime? createdAt;
  final PeminjamanModel? peminjaman;

  PerpanjanganModel({
    required this.id,
    required this.peminjamanId,
    required this.tanggalJatuhTempoBaru,
    this.alasanPerpanjangan,
    this.status = 'menunggu',
    this.createdAt,
    this.peminjaman,
  });

  factory PerpanjanganModel.fromMap(Map<String, dynamic> map) {
    return PerpanjanganModel(
      id: map['id'] ?? '',
      // FIX: Rename peminjamamId → peminjamanId
      peminjamanId: map['peminjaman_id'] ?? '',
      // FIX: Tambah null safety untuk tanggalJatuhTempoBaru
      tanggalJatuhTempoBaru: map['tanggal_jatuh_tempo_baru'] != null
          ? DateTime.parse(map['tanggal_jatuh_tempo_baru'])
          : DateTime.now(),
      alasanPerpanjangan: map['alasan_perpanjangan'],
      // FIX: Parse status dari database
      status: map['status'] ?? 'menunggu',
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
      // FIX: Rename peminjamamId → peminjamanId
      'peminjaman_id': peminjamanId,
      'tanggal_jatuh_tempo_baru': tanggalJatuhTempoBaru.toIso8601String(),
      'alasan_perpanjangan': alasanPerpanjangan,
      'status': status,
    };
  }

  // FIX: Tambah copyWith
  PerpanjanganModel copyWith({
    String? peminjamanId,
    DateTime? tanggalJatuhTempoBaru,
    String? alasanPerpanjangan,
    String? status,
    DateTime? createdAt,
    PeminjamanModel? peminjaman,
  }) {
    return PerpanjanganModel(
      id: id,
      peminjamanId: peminjamanId ?? this.peminjamanId,
      tanggalJatuhTempoBaru:
          tanggalJatuhTempoBaru ?? this.tanggalJatuhTempoBaru,
      alasanPerpanjangan: alasanPerpanjangan ?? this.alasanPerpanjangan,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      peminjaman: peminjaman ?? this.peminjaman,
    );
  }
}
