import 'peminjaman_model.dart';

class PerpanjanganModel {
  final String id;
  final String peminjamanId;
  final DateTime tanggalJatuhTempoBaru;
  final String? alasanPerpanjangan;
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
    final tanggalRaw =
        map['tanggal_jatuh_tempo_baru'] ?? map['rencana_kembali_baru'];

    return PerpanjanganModel(
      id: map['id'] ?? '',
      peminjamanId: map['peminjaman_id'] ?? '',
<<<<<<< HEAD
=======
      // FIX: Tambah null safety untuk tanggalJatuhTempoBaru
>>>>>>> 190e2f40caab643be0b09682bd87d23eac3662a1
      tanggalJatuhTempoBaru: tanggalRaw != null
          ? DateTime.parse(tanggalRaw.toString())
          : DateTime.now(),
      alasanPerpanjangan: map['alasan_perpanjangan'],
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
      'peminjaman_id': peminjamanId,
      'tanggal_jatuh_tempo_baru': tanggalJatuhTempoBaru.toIso8601String(),
      'alasan_perpanjangan': alasanPerpanjangan,
      'status': status,
    };
  }

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
