import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/peminjaman_model.dart';
import '../models/pengembalian_model.dart';
import '../models/perpanjangan_model.dart';

class ApprovalProvider extends ChangeNotifier {
  List<PeminjamanModel> _pendingPeminjaman = [];
  List<PeminjamanModel> _activePeminjaman = [];
  List<PeminjamanModel> _historyPeminjaman = [];
  List<PengembalianModel> _pengembalian = [];
  List<PerpanjanganModel> _perpanjangan = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _adminApprovalChannel;

  List<PeminjamanModel> get pendingPeminjaman => _pendingPeminjaman;
  List<PeminjamanModel> get activePeminjaman => _activePeminjaman;
  List<PeminjamanModel> get historyPeminjaman => _historyPeminjaman;
  List<PengembalianModel> get pengembalian => _pengembalian;
  List<PerpanjanganModel> get perpanjangan => _perpanjangan;

  List<PengembalianModel> get pendingPengembalian =>
      _pengembalian.where((e) => e.status == 'menunggu_konfirmasi').toList();
  List<PerpanjanganModel> get pendingPerpanjangan =>
      _perpanjangan.where((e) => e.status == 'menunggu').toList();

  List<dynamic> get allPendingApprovals => [
    ...pendingPeminjaman,
    ...pendingPengembalian,
    ...pendingPerpanjangan,
  ];

  List<PeminjamanModel> get peminjaman => [
    ..._activePeminjaman,
    ..._historyPeminjaman,
  ];

  List<PeminjamanModel> get terlambat =>
      _activePeminjaman.where((p) => p.isTerlambat).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Map<String, dynamic> _toStringKeyMap(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final map = <String, dynamic>{};
    raw.forEach((key, value) {
      map[key.toString()] = value;
    });
    return map;
  }

  bool _isPlaceholderUserData(Map<String, dynamic> user) {
    final nama = (user['nama'] ?? '').toString().trim().toLowerCase();
    final dept = (user['departemen'] ?? '').toString().trim();
    final wa = (user['no_whatsapp'] ?? '').toString().trim();

    return user.isEmpty ||
        nama.isEmpty ||
        nama == 'user baru' ||
        nama == 'guest user' ||
        dept.isEmpty ||
        dept == '-' ||
        wa.isEmpty ||
        wa == '-';
  }

  Future<void> _incrementItemStockSafely(String barangId) async {
    try {
      await SupabaseService.client.rpc(
        'increment_item_stock',
        params: {'target_id': barangId},
      );
      return;
    } catch (e) {
      debugPrint(
        'RPC increment_item_stock unavailable, fallback update volume: $e',
      );
    }

    final barang = await SupabaseService.table(
      'barang',
    ).select('volume').eq('id', barangId).single();
    final currentVolume = (barang['volume'] is num)
        ? (barang['volume'] as num).toInt()
        : 0;

    await SupabaseService.table(
      'barang',
    ).update({'volume': currentVolume + 1}).eq('id', barangId);
  }

  Future<void> _decrementItemStockSafely(String barangId) async {
    try {
      await SupabaseService.client.rpc(
        'decrement_item_stock',
        params: {'target_id': barangId},
      );
      return;
    } catch (e) {
      debugPrint(
        'RPC decrement_item_stock unavailable, fallback update volume: $e',
      );
    }

    final barang = await SupabaseService.table(
      'barang',
    ).select('volume').eq('id', barangId).single();
    final currentVolume = (barang['volume'] is num)
        ? (barang['volume'] as num).toInt()
        : 0;

    // Pastikan volume tidak minus
    if (currentVolume > 0) {
      await SupabaseService.table(
        'barang',
      ).update({'volume': currentVolume - 1}).eq('id', barangId);
    }
  }

  Future<List<PeminjamanModel>> _mapPeminjamanWithFallback(List data) async {
    final rows = data.map((e) => _toStringKeyMap(e)).toList();

    final missingUserIds = <String>{};
    final missingBarangIds = <String>{};

    for (final row in rows) {
      final userJoin = _toStringKeyMap(row['users']);
      final barangJoin = _toStringKeyMap(row['barang']);

      final userId = row['user_id']?.toString();
      final barangId = row['barang_id']?.toString();

      if (_isPlaceholderUserData(userJoin) &&
          userId != null &&
          userId.isNotEmpty) {
        missingUserIds.add(userId);
      }
      if (barangJoin.isEmpty && barangId != null && barangId.isNotEmpty) {
        missingBarangIds.add(barangId);
      }
    }

    final usersById = <String, Map<String, dynamic>>{};
    if (missingUserIds.isNotEmpty) {
      final usersRes = await SupabaseService.table('users')
          .select('id, nama, departemen, no_whatsapp')
          .inFilter('id', missingUserIds.toList());

      for (final u in (usersRes as List)) {
        final map = _toStringKeyMap(u);
        final id = map['id']?.toString();
        if (id != null && id.isNotEmpty) {
          usersById[id] = map;
        }
      }
    }

    final barangById = <String, Map<String, dynamic>>{};
    if (missingBarangIds.isNotEmpty) {
      final barangRes = await SupabaseService.table('barang')
          .select('id, nama_barang, kode_barang')
          .inFilter('id', missingBarangIds.toList());

      for (final b in (barangRes as List)) {
        final map = _toStringKeyMap(b);
        final id = map['id']?.toString();
        if (id != null && id.isNotEmpty) {
          barangById[id] = map;
        }
      }
    }

    return rows.map((row) {
      final userId = row['user_id']?.toString();
      final barangId = row['barang_id']?.toString();

      final userJoin = _toStringKeyMap(row['users']);
      final barangJoin = _toStringKeyMap(row['barang']);

      if (_isPlaceholderUserData(userJoin) &&
          userId != null &&
          usersById.containsKey(userId)) {
        final fallbackUser = usersById[userId] ?? <String, dynamic>{};
        if (!_isPlaceholderUserData(fallbackUser)) {
          row['users'] = fallbackUser;
        }
      }

      if (barangJoin.isEmpty &&
          barangId != null &&
          barangById.containsKey(barangId)) {
        row['barang'] = barangById[barangId];
      }

      return PeminjamanModel.fromMap(row);
    }).toList();
  }

  Future<void> _trySyncCurrentUserRowFromMetadata(String userId) async {
    final authUser = SupabaseService.auth.currentUser;
    if (authUser == null || authUser.id != userId) return;

    final meta = authUser.userMetadata ?? const <String, dynamic>{};
    final nama = (meta['nama'] ?? meta['full_name'] ?? '').toString().trim();
    final departemen = (meta['departemen'] ?? meta['department'] ?? '')
        .toString()
        .trim();
    final nim = (meta['nim'] ?? meta['student_id'] ?? '').toString().trim();
    final noWhatsapp = (meta['no_whatsapp'] ?? meta['phone'] ?? '')
        .toString()
        .trim();

    if (nama.isEmpty &&
        departemen.isEmpty &&
        nim.isEmpty &&
        noWhatsapp.isEmpty) {
      return;
    }

    try {
      await SupabaseService.table('users')
          .update({
            'nama': nama.isEmpty ? 'User Baru' : nama,
            'departemen': departemen.isEmpty ? '-' : departemen,
            'nim': nim.isEmpty ? null : nim,
            'no_whatsapp': noWhatsapp.isEmpty ? null : noWhatsapp,
          })
          .eq('id', userId);
    } catch (_) {}
  }

  Future<void> _refreshAllAdminApprovalLists() async {
    await Future.wait([
      fetchPendingPeminjaman(emitLoading: false),
      fetchActivePeminjaman(emitLoading: false),
      fetchPengembalian(emitLoading: false),
      fetchPerpanjangan(emitLoading: false),
    ]);
  }

  Future<void> fetchAllForAdmin() async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchPendingPeminjaman(emitLoading: false),
        fetchActivePeminjaman(emitLoading: false),
        fetchPengembalian(emitLoading: false),
        fetchPerpanjangan(emitLoading: false),
      ]);
    } catch (e) {
      debugPrint('Error fetchAllForAdmin: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPendingPeminjaman({bool emitLoading = true}) async {
    if (emitLoading) _setLoading(true);
    try {
      final data = await SupabaseService.table('peminjaman')
          .select(
            '*, '
            'barang:barang!peminjaman_barang_id_fkey(*), '
            'users:users!peminjaman_user_id_fkey(*)',
          )
          .eq('status', 'menunggu')
          .order('created_at', ascending: false);

      _pendingPeminjaman = await _mapPeminjamanWithFallback(data as List);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchPendingPeminjaman: $e');
      _setError('Gagal memuat permohonan peminjaman.');
    } finally {
      if (emitLoading) _setLoading(false);
    }
  }

  Future<void> fetchActivePeminjaman({bool emitLoading = true}) async {
    if (emitLoading) _setLoading(true);
    try {
      final data = await SupabaseService.table('peminjaman')
          .select(
            '*, '
            'barang:barang!peminjaman_barang_id_fkey(*), '
            'users:users!peminjaman_user_id_fkey(*)',
          )
          .or('status.eq.disetujui,status.eq.menunggu_konfirmasi')
          .order('created_at', ascending: false);

      _activePeminjaman = await _mapPeminjamanWithFallback(data as List);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchActivePeminjaman: $e');
    } finally {
      if (emitLoading) _setLoading(false);
    }
  }

  Future<void> fetchUserPeminjaman(String userId) async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchUserActivePeminjaman(userId),
        fetchUserHistory(userId),
      ]);
    } catch (e) {
      debugPrint('Error fetchUserPeminjaman: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserActivePeminjaman(String userId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table('peminjaman')
          .select('*, barang(*)')
          .eq('user_id', userId)
          .or(
            'status.eq.disetujui,status.eq.menunggu_konfirmasi,status.eq.menunggu',
          )
          .order('created_at', ascending: false);
      _activePeminjaman = (data as List)
          .map((e) => PeminjamanModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetchUserActivePeminjaman: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPengembalian({bool emitLoading = true}) async {
    if (emitLoading) _setLoading(true);
    try {
      final data = await SupabaseService.table('pengembalian')
          .select('*, peminjaman(*, barang(*), users(*))')
          .eq('status', 'menunggu_konfirmasi')
          .order('created_at', ascending: false);
      _pengembalian = (data as List)
          .map((e) => PengembalianModel.fromMap(e))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchPengembalian: $e');
    } finally {
      if (emitLoading) _setLoading(false);
    }
  }

  Future<void> fetchPerpanjangan({bool emitLoading = true}) async {
    if (emitLoading) _setLoading(true);
    try {
      final data = await SupabaseService.table('perpanjangan')
          .select('*, peminjaman(*, barang(*), users(*))')
          .order('created_at', ascending: false);
      _perpanjangan = (data as List)
          .map((e) => PerpanjanganModel.fromMap(e))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchPerpanjangan: $e');
    } finally {
      if (emitLoading) _setLoading(false);
    }
  }

  Future<void> fetchUserHistory(String userId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table('peminjaman')
          .select('*, barang(*)')
          .eq('user_id', userId)
          .inFilter('status', ['selesai', 'ditolak', 'dibatalkan'])
          .order('created_at', ascending: false);
      _historyPeminjaman = (data as List)
          .map((e) => PeminjamanModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetchUserHistory: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startAdminApprovalRealtime() async {
    if (_adminApprovalChannel != null) return;

    _adminApprovalChannel = SupabaseService.client
        .channel('admin-approval-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'peminjaman',
          callback: (_) {
            _refreshAllAdminApprovalLists();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'peminjaman',
          callback: (_) {
            _refreshAllAdminApprovalLists();
          },
        )
        .subscribe();
  }

  Future<void> stopAdminApprovalRealtime() async {
    final channel = _adminApprovalChannel;
    if (channel == null) return;
    await SupabaseService.client.removeChannel(channel);
    _adminApprovalChannel = null;
  }

  Future<bool> submitPeminjaman({
    required String userId,
    required String barangId,
    required DateTime tanggalPinjam,
    required DateTime rencanaKembali,
    String? alasan,
    String? fotoUrl,
  }) async {
    try {
      _setError(null);

      await _trySyncCurrentUserRowFromMetadata(userId);

      await SupabaseService.table('peminjaman').insert({
        'user_id': userId,
        'barang_id': barangId,
        'tanggal_pinjam': tanggalPinjam.toIso8601String(),
        'rencana_kembali': rencanaKembali.toIso8601String(),
        'alasan_meminjam': alasan,
        'foto_sebelum_pinjam_url': fotoUrl,
        'status': 'menunggu',
      });

      await _decrementItemStockSafely(barangId);

      try {
        final userRes = await SupabaseService.table(
          'users',
        ).select('nama').eq('id', userId).single();
        final barangRes = await SupabaseService.table(
          'barang',
        ).select('nama_barang').eq('id', barangId).single();

        await SupabaseService.table('notifications').insert({
          'user_id': null,
          'title': 'Permohonan Peminjaman Baru',
          'message':
              '${userRes['nama']} mengajukan peminjaman ${barangRes['nama_barang']}',
          'type': 'peminjaman',
          'is_read': false,
        });
      } catch (e) {
        // Abaikan error notifikasi agar submit peminjaman tetap sukses.
      }

      await fetchUserPeminjaman(userId);

      return true;
    } catch (e) {
      _setError('Gagal mengajukan peminjaman: $e');
      debugPrint('Error: $e');
      return false;
    }
  }

  Future<bool> submitPengembalian({
    required String peminjamanId,
    required String fotoDepanUrl,
    required String fotoBelakangUrl,
    String? catatan,
  }) async {
    _setLoading(true);
    try {
      await SupabaseService.table('pengembalian').insert({
        'peminjaman_id': peminjamanId,
        'tanggal_dikembalikan': DateTime.now().toIso8601String(),
        'foto_kembali_depan_url': fotoDepanUrl,
        'foto_kembali_belakang_url': fotoBelakangUrl,
        'catatan_pengembalian': catatan,
        'status': 'menunggu_konfirmasi',
      });

      await SupabaseService.table(
        'peminjaman',
      ).update({'status': 'menunggu_konfirmasi'}).eq('id', peminjamanId);

      try {
        final pRes = await SupabaseService.table('peminjaman')
            .select('users(nama), barang(nama_barang)')
            .eq('id', peminjamanId)
            .single();

        await SupabaseService.table('notifications').insert({
          'user_id': null,
          'title': 'Pengembalian Aset',
          'message':
              '${pRes['users']['nama']} telah mengembalikan ${pRes['barang']['nama_barang']}. Mohon verifikasi kondisi aset.',
          'type': 'pengembalian',
          'is_read': false,
        });
      } catch (e) {
        debugPrint('Error sending admin notification: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error submitPengembalian: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<int> getExtensionCount(String peminjamanId) async {
    try {
      final res = await SupabaseService.table('perpanjangan')
          .select('id')
          .eq('peminjaman_id', peminjamanId)
          .eq('status', 'disetujui');
      return (res as List).length;
    } catch (e) {
      debugPrint('Error getExtensionCount: $e');
      return 0;
    }
  }

  Future<bool> submitPerpanjangan({
    required String peminjamanId,
    required DateTime tanggalBaru,
    required String alasan,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final existingPending = await SupabaseService.table('perpanjangan')
          .select('id')
          .eq('peminjaman_id', peminjamanId)
          .eq('status', 'menunggu')
          .limit(1);

      if ((existingPending as List).isNotEmpty) {
        _setError('Permintaan perpanjangan sebelumnya masih diproses admin.');
        return false;
      }

      final sessionUserId = SupabaseService.client.auth.currentUser?.id;
      if (sessionUserId == null) {
        _setError('Sesi login tidak ditemukan. Silakan login ulang.');
        return false;
      }

      final pinjamData = await SupabaseService.table(
        'peminjaman',
      ).select('user_id').eq('id', peminjamanId).single();
      final ownerUserId = pinjamData['user_id']?.toString();
      if (ownerUserId == null || ownerUserId != sessionUserId) {
        _setError(
          'Anda tidak memiliki akses untuk perpanjangan peminjaman ini.',
        );
        return false;
      }

      final payloadVariants = <Map<String, dynamic>>[
        {
          'peminjaman_id': peminjamanId,
          'user_id': sessionUserId,
          'tanggal_jatuh_tempo_baru': tanggalBaru.toIso8601String(),
          'alasan_perpanjangan': alasan,
          'status': 'menunggu',
        },
        {
          'peminjaman_id': peminjamanId,
          'user_id': sessionUserId,
          'rencana_kembali_baru': tanggalBaru.toIso8601String(),
          'alasan_perpanjangan': alasan,
          'status': 'menunggu',
        },
        {
          'peminjaman_id': peminjamanId,
          'tanggal_jatuh_tempo_baru': tanggalBaru.toIso8601String(),
          'alasan_perpanjangan': alasan,
          'status': 'menunggu',
        },
        {
          'peminjaman_id': peminjamanId,
          'rencana_kembali_baru': tanggalBaru.toIso8601String(),
          'alasan_perpanjangan': alasan,
          'status': 'menunggu',
        },
      ];

      PostgrestException? lastSchemaException;
      var inserted = false;

      for (final payload in payloadVariants) {
        try {
          await SupabaseService.table('perpanjangan').insert(payload);
          inserted = true;
          break;
        } on PostgrestException catch (e) {
          final lowerMessage = e.message.toLowerCase();
          final lowerDetails = (e.details?.toString() ?? '').toLowerCase();
          final isSchemaMismatch =
              lowerMessage.contains('column') ||
              lowerDetails.contains('column') ||
              lowerMessage.contains('tanggal_jatuh_tempo_baru') ||
              lowerDetails.contains('tanggal_jatuh_tempo_baru') ||
              lowerMessage.contains('rencana_kembali_baru') ||
              lowerDetails.contains('rencana_kembali_baru') ||
              lowerMessage.contains('user_id') ||
              lowerDetails.contains('user_id');

          if (!isSchemaMismatch) {
            rethrow;
          }

          lastSchemaException = e;
        }
      }

      if (!inserted) {
        if (lastSchemaException != null) {
          throw lastSchemaException;
        }
        throw Exception('Gagal menyimpan data perpanjangan.');
      }

      await SupabaseService.table(
        'peminjaman',
      ).update({'status': 'menunggu_konfirmasi'}).eq('id', peminjamanId);

      try {
        final pRes = await SupabaseService.table('peminjaman')
            .select('users(nama), barang(nama_barang)')
            .eq('id', peminjamanId)
            .single();

        await SupabaseService.table('notifications').insert({
          'user_id': null,
          'title': 'Permohonan Perpanjangan',
          'message':
              '${pRes['users']['nama']} mengajukan perpanjangan untuk ${pRes['barang']['nama_barang']}.',
          'type': 'perpanjangan',
          'is_read': false,
        });
      } catch (e) {
        debugPrint('Error sending admin notification: $e');
      }

      return true;
    } on PostgrestException catch (e) {
      final detailsText = e.details?.toString();
      final parts = <String>[
        if (e.message.isNotEmpty) e.message,
        if (detailsText != null && detailsText.isNotEmpty) detailsText,
      ];
      final readable = parts.join(' | ');
      _setError('Gagal mengajukan perpanjangan: $readable');
      debugPrint('Error submitPerpanjangan: $readable');
      return false;
    } catch (e) {
      _setError('Gagal mengajukan perpanjangan: $e');
      debugPrint('Error submitPerpanjangan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStatusPeminjaman(
    String id,
    String status,
    String barangId,
  ) async {
    _setLoading(true);
    try {
      await SupabaseService.table(
        'peminjaman',
      ).update({'status': status}).eq('id', id);

      if (status == 'ditolak' || status == 'dibatalkan') {
        await _incrementItemStockSafely(barangId);
      }

      await _refreshAllAdminApprovalLists();
      return true;
    } catch (e) {
      debugPrint('Error updateStatusPeminjaman: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStatusPengembalian({
    required String pengembalianId,
    String? peminjamanId,
  }) async {
    _setLoading(true);
    try {
      await SupabaseService.table(
        'pengembalian',
      ).update({'status': 'selesai'}).eq('id', pengembalianId);

      if (peminjamanId != null) {

        final peminjamanData = await SupabaseService.table('peminjaman')
            .select('barang_id, user_id, barang(nama_barang)')
            .eq('id', peminjamanId)
            .single();
        final barangId = peminjamanData['barang_id'];
        final userId = peminjamanData['user_id'];
        final assetName = peminjamanData['barang']['nama_barang'];

        await SupabaseService.table(
          'peminjaman',
        ).update({'status': 'selesai'}).eq('id', peminjamanId);

        await _incrementItemStockSafely(barangId);

        try {
          await SupabaseService.table('notifications').insert({
            'user_id': userId,
            'title': 'Pengembalian Dikonfirmasi',
            'message':
                'Admin telah mengkonfirmasi pengembalian $assetName. Terima kasih!',
            'type': 'pengembalian',
            'is_read': false,
          });
        } catch (e) {
          debugPrint('Error sending user notification: $e');
        }
      }

      await _refreshAllAdminApprovalLists();
      return true;
    } catch (e) {
      debugPrint('Error updateStatusPengembalian: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStatusPerpanjangan({
    required String perpanjanganId,
    required String status,
    String? peminjamanId,
    DateTime? tanggalBaruKembali,
  }) async {
    _setLoading(true);
    try {
      await SupabaseService.table(
        'perpanjangan',
      ).update({'status': status}).eq('id', perpanjanganId);

      if (status == 'disetujui' &&
          peminjamanId != null &&
          tanggalBaruKembali != null) {
        final pData = await SupabaseService.table('peminjaman')
            .select('user_id, barang(nama_barang)')
            .eq('id', peminjamanId)
            .single();
        final userId = pData['user_id'];
        final assetName = pData['barang']['nama_barang'];

        await SupabaseService.table('peminjaman')
            .update({
              'rencana_kembali': tanggalBaruKembali.toIso8601String(),
              'status': 'disetujui',
            })
            .eq('id', peminjamanId);
        try {
          await SupabaseService.table('notifications').insert({
            'user_id': userId,
            'title': 'Perpanjangan Disetujui',
            'message':
                'Permohonan perpanjangan $assetName telah disetujui oleh Admin.',
            'type': 'perpanjangan',
            'is_read': false,
          });
        } catch (e) {
          debugPrint('Error sending user notification: $e');
        }
      } else if (status == 'ditolak' && peminjamanId != null) {

        await SupabaseService.table(
          'peminjaman',
        ).update({'status': 'disetujui'}).eq('id', peminjamanId);
      }

      await _refreshAllAdminApprovalLists();
      return true;
    } catch (e) {
      debugPrint('Error updateStatusPerpanjangan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadFotoKondisi(
    Uint8List bytes,
    String extension,
    String filePrefix,
  ) async {
    try {

      final normalizedPrefix = filePrefix.trim().isEmpty
          ? 'kondisi'
          : filePrefix.trim();
      final fileName =
          '${normalizedPrefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'pengembalian/$fileName';
      const bucketName = 'foto_barang';

      await SupabaseService.storage
          .from(bucketName)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}',
              upsert: true,
            ),
          );

      return SupabaseService.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploadFotoKondisi (bucket: pengembalian): $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    final channel = _adminApprovalChannel;
    if (channel != null) {
      SupabaseService.client.removeChannel(channel);
      _adminApprovalChannel = null;
    }
    super.dispose();
  }
}
