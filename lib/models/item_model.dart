class ItemModel {
  final String id;
  final String kodeBarang;
  final String namaBarang;
  final int volume;
  final String satuan;
  final String asalBarang;
  final String kondisiBarang;
  final String? spesifikasiBarang;
  final int? tahunPembuatan;
  final int? tersedia;
  final double? hargaBarang;
  final String? dokumenNotaUrl;
  final String? keteranganTambahan;
  final DateTime? tanggalPembukuan;
  final DateTime? createdAt;
  final String? fotoUrl;

  ItemModel({
    required this.id,
    required this.kodeBarang,
    required this.namaBarang,
    required this.volume,
    required this.satuan,
    required this.asalBarang,
    required this.kondisiBarang,
    this.spesifikasiBarang,
    this.tahunPembuatan,
    this.hargaBarang,
    this.tersedia,
    this.dokumenNotaUrl,
    this.keteranganTambahan,
    this.tanggalPembukuan,
    this.createdAt,
    this.fotoUrl,
  });

  bool get isAvailable => kondisiBarang == 'Baik' && (tersedia ?? 0) > 0;

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] ?? '',
      kodeBarang: map['kode_barang'] ?? '',
      namaBarang: map['nama_barang'] ?? '',
      volume: map['volume'] ?? 0,
      tersedia: map['tersedia'] != null
          ? int.tryParse(map['tersedia'].toString())
          : null,
      satuan: map['satuan'] ?? '',
      asalBarang: map['asal_barang'] ?? '',
      kondisiBarang: map['kondisi_barang'] ?? 'Baik',
      spesifikasiBarang: map['spesifikasi_barang'],
      tahunPembuatan: map['tahun_pembuatan'],
      hargaBarang: map['harga_barang'] != null
          ? double.tryParse(map['harga_barang'].toString())
          : null,
      dokumenNotaUrl: map['dokumen_nota_url'],
      keteranganTambahan: map['keterangan_tambahan'],
      tanggalPembukuan: map['tanggal_pembukuan'] != null
          ? DateTime.parse(map['tanggal_pembukuan'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      fotoUrl: map['foto_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'volume': volume,
      'tersedia': tersedia,
      'satuan': satuan,
      'asal_barang': asalBarang,
      'kondisi_barang': kondisiBarang,
      'spesifikasi_barang': spesifikasiBarang,
      'tahun_pembuatan': tahunPembuatan,
      'harga_barang': hargaBarang,
      'dokumen_nota_url': dokumenNotaUrl,
      'keterangan_tambahan': keteranganTambahan,
      'tanggal_pembukuan': tanggalPembukuan?.toIso8601String(),
      'foto_url': fotoUrl,
    };
  }

  ItemModel copyWith({
    String? id,
    String? kodeBarang,
    String? namaBarang,
    int? volume,
    int? tersedia,
    String? satuan,
    String? asalBarang,
    String? kondisiBarang,
    String? spesifikasiBarang,
    int? tahunPembuatan,
    double? hargaBarang,
    String? dokumenNotaUrl,
    String? keteranganTambahan,
    DateTime? tanggalPembukuan,
    DateTime? createdAt,
    String? fotoUrl,
  }) {
    return ItemModel(
      id: id ?? this.id,
      kodeBarang: kodeBarang ?? this.kodeBarang,
      namaBarang: namaBarang ?? this.namaBarang,
      volume: volume ?? this.volume,
      tersedia: tersedia ?? this.tersedia,
      satuan: satuan ?? this.satuan,
      asalBarang: asalBarang ?? this.asalBarang,
      kondisiBarang: kondisiBarang ?? this.kondisiBarang,
      spesifikasiBarang: spesifikasiBarang ?? this.spesifikasiBarang,
      tahunPembuatan: tahunPembuatan ?? this.tahunPembuatan,
      hargaBarang: hargaBarang ?? this.hargaBarang,
      dokumenNotaUrl: dokumenNotaUrl ?? this.dokumenNotaUrl,
      keteranganTambahan: keteranganTambahan ?? this.keteranganTambahan,
      tanggalPembukuan: tanggalPembukuan ?? this.tanggalPembukuan,
      createdAt: createdAt ?? this.createdAt,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}
