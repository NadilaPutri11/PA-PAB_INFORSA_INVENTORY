class UserModel {
  final String id;
  final String nama;
  final String departemen;
  final String? nim;
  final String? noWhatsapp;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.nama,
    required this.departemen,
    this.nim,
    this.noWhatsapp,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      nama: map['nama'] ?? '',
      departemen: map['departemen'] ?? '',
      nim: map['nim'],
      noWhatsapp: map['no_whatsapp'],
      avatarUrl: map['avatar_url'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'departemen': departemen,
      'nim': nim,
      'no_whatsapp': noWhatsapp,
      'avatar_url': avatarUrl,
    };
  }

  UserModel copyWith({
    String? nama,
    String? departemen,
    String? nim,
    String? noWhatsapp,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      nama: nama ?? this.nama,
      departemen: departemen ?? this.departemen,
      nim: nim ?? this.nim,
      noWhatsapp: noWhatsapp ?? this.noWhatsapp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}
