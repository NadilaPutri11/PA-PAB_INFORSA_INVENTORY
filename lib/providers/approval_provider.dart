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

  List<PeminjamanModel> get pendingPeminjaman => _pendingPeminjaman;
  List<PeminjamanModel> get activePeminjaman => _activePeminjaman;
  List<PeminjamanModel> get historyPeminjaman => _historyPeminjaman;
  List<PengembalianModel> get pengembalian => _pengembalian;
  List<PerpanjanganModel> get perpanjangan => _perpanjangan;

  List<PengembalianModel> get pendingPengembalian =>
      _pengembalian.where((e) => e.status == 'menunggu_konfirmasi').toList();
  List<PerpanjanganModel> get pendingPerpanjangan =>
      _perpanjangan.where((e) => e.status == 'menunggu').toList();

  // Combined list for general usage (e.g. Activity Page)
  List<dynamic> get allPendingApprovals => [
        ...pendingPeminjaman,
        ...pendingPengembalian,
        ...pendingPerpanjangan,
      ];

  // Combined list for general usage (e.g. Activity Page)
  List<PeminjamanModel> get peminjaman => [
    ..._activePeminjaman,
    ..._historyPeminjaman,
  ];

  // Overdue borrowings for User Dashboard
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

  // ── Fetching ──────────────────────────────────────────────────────────────

  Future<void> fetchAllForAdmin() async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchPendingPeminjaman(),
        fetchActivePeminjaman(),
        fetchPengembalian(),
        fetchPerpanjangan(),
      ]);
    } catch (e) {
      debugPrint('Error fetchAllForAdmin: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPendingPeminjaman() async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table('peminjaman')
          .select('*, barang(*), users(*)')
          .eq('status', 'menunggu')
          .order('created_at', ascending: false);
      _pendingPeminjaman = (data as List)
          .map((e) => PeminjamanModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetchPendingPeminjaman: $e');
      _setError('Gagal memuat permohonan peminjaman.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchActivePeminjaman() async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table('peminjaman')
          .select('*, barang(*), users(*)')
          .or('status.eq.disetujui,status.eq.menunggu_konfirmasi')
          .order('created_at', ascending: false);
      _activePeminjaman = (data as List)
          .map((e) => PeminjamanModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetchActivePeminjaman: $e');
    } finally {
      _setLoading(false);
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
          .or('status.eq.disetujui,status.eq.menunggu_konfirmasi')
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

  Future<void> fetchPengembalian() async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table('pengembalian')
          .select('*, peminjaman(*, barang(*), users(*))')
          .eq('status', 'menunggu_konfirmasi')
          .order('created_at', ascending: false);
      _pengembalian = (data as List)
          .map((e) => PengembalianModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetchPengembalian: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPerpanjangan() async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table('perpanjangan')
          .select('*, peminjaman(*, barang(*), users(*))')
          .order('created_at', ascending: false);
      _perpanjangan = (data as List)
          .map((e) => PerpanjanganModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetchPerpanjangan: $e');
    } finally {
      _setLoading(false);
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

  // ── Submissions ────────────────────────────────────────────────────────────

  // FIX: Sesuaikan nama parameter dengan kolom di Table Editor
  Future<bool> submitPeminjaman({
    required String userId,
    required String barangId,
    required DateTime tanggalPinjam,
    required DateTime rencanaKembali,
    String? alasan,
    String? fotoUrl, // Parameter tunggal berisi gabungan URL
  }) async {
    try {
      await SupabaseService.table('peminjaman').insert({
        'user_id': userId,
        'barang_id': barangId,
        'tanggal_pinjam': tanggalPinjam.toIso8601String(),
        'rencana_kembali': rencanaKembali.toIso8601String(),
        'alasan_meminjam': alasan,
        'foto_sebelum_pinjam_url': fotoUrl, // Masuk ke kolom yang sama
        'status': 'menunggu',
      });
      return true;
    } catch (e) {
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
      // 1. Insert ke tabel pengembalian
      await SupabaseService.table('pengembalian').insert({
        'peminjaman_id': peminjamanId,
        'tanggal_dikembalikan': DateTime.now().toIso8601String(),
        'foto_kembali_depan_url': fotoDepanUrl,
        'foto_kembali_belakang_url': fotoBelakangUrl,
        'catatan_pengembalian': catatan,
        'status': 'menunggu_konfirmasi',
      });

      // 2. Update status peminjaman menjadi menunggu_konfirmasi
      await SupabaseService.table(
        'peminjaman',
      ).update({'status': 'menunggu_konfirmasi'}).eq('id', peminjamanId);

      return true;
    } catch (e) {
      debugPrint('Error submitPengembalian: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitPerpanjangan({
    required String peminjamanId,
    required DateTime tanggalBaru,
    required String alasan,
  }) async {
    _setLoading(true);
    try {
      // 1. Simpan record perpanjangan
      await SupabaseService.table('perpanjangan').insert({
        'peminjaman_id': peminjamanId,
        'rencana_kembali_baru': tanggalBaru.toIso8601String(),
        'alasan_perpanjangan': alasan,
        'status': 'menunggu',
      });

      // 2. Tandai peminjaman sedang dalam proses konfirmasi perpanjangan
      // Kita gunakan status 'menunggu_konfirmasi' agar muncul di dashboard admin
      await SupabaseService.table(
        'peminjaman',
      ).update({'status': 'menunggu_konfirmasi'}).eq('id', peminjamanId);

      return true;
    } catch (e) {
      debugPrint('Error submitPerpanjangan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Admin Actions ──────────────────────────────────────────────────────────

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

      // Jika ditolak atau dibatalkan, kembalikan stok secara atomik
      if (status == 'ditolak' || status == 'dibatalkan') {
        await SupabaseService.client.rpc(
          'increment_item_stock',
          params: {'target_id': barangId},
        );
      }

      await fetchPendingPeminjaman();
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
      // 1. Update status pengembalian
      await SupabaseService.table(
        'pengembalian',
      ).update({'status': 'selesai'}).eq('id', pengembalianId);

      if (peminjamanId != null) {
        // 2. Ambil data peminjaman untuk dapat barang_id
        final peminjamanData = await SupabaseService.table(
          'peminjaman',
        ).select('barang_id').eq('id', peminjamanId).single();
        final barangId = peminjamanData['barang_id'];

        // 3. Set status peminjaman ke selesai
        await SupabaseService.table(
          'peminjaman',
        ).update({'status': 'selesai'}).eq('id', peminjamanId);

        // 4. Kembalikan stok secara atomik
        await SupabaseService.client.rpc(
          'increment_item_stock',
          params: {'target_id': barangId},
        );
      }

      await fetchPengembalian();
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
      // 1. Update status perpanjangan
      await SupabaseService.table(
        'perpanjangan',
      ).update({'status': status}).eq('id', perpanjanganId);

      // 2. Jika disetujui, update tanggal_kembali di tabel peminjaman
      if (status == 'disetujui' &&
          peminjamanId != null &&
          tanggalBaruKembali != null) {
        await SupabaseService.table('peminjaman')
            .update({
              'rencana_kembali': tanggalBaruKembali.toIso8601String(),
              'status': 'disetujui',
            })
            .eq('id', peminjamanId);
      } else if (status == 'ditolak' && peminjamanId != null) {
        // Kembalikan ke disetujui agar muncul lagi sebagai aktif normal
        await SupabaseService.table(
          'peminjaman',
        ).update({'status': 'disetujui'}).eq('id', peminjamanId);
      }

      await fetchPerpanjangan();
      return true;
    } catch (e) {
      debugPrint('Error updateStatusPerpanjangan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── File Upload ────────────────────────────────────────────────────────────

  Future<String?> uploadFotoKondisi(
    Uint8List bytes,
    String extension,
    String bucketName,
  ) async {
    try {
      // Gunakan timestamp untuk unik dan cache busting
      final fileName =
          'kondisi_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'pengembalian/$fileName';

      // Gunakan FileOptions untuk menentukan contentType sesuai batasan di Supabase
      await SupabaseService.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}',
              upsert: true,
            ),
          );

      return SupabaseService.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploadFotoKondisi ($bucketName): $e');
      rethrow;
    }
  }
}
