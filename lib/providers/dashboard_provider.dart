import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class DashboardMetrics {
  final int activeLoans;
  final int totalExtensions;
  final double extensionTrend; // percentage change
  final Map<String, int> transactionStatus; // status -> count
  final List<DailyStats> usageStats;

  DashboardMetrics({
    required this.activeLoans,
    required this.totalExtensions,
    required this.extensionTrend,
    required this.transactionStatus,
    required this.usageStats,
  });
}

class DailyStats {
  final DateTime date;
  final int count;
  DailyStats(this.date, this.count);
}

class UserRegistrationData {
  final String id;
  final String nama;
  final String email;
  final DateTime tanggalRegistrasi;
  final String statusAkun;
  final int totalPeminjaman;
  final String? noWhatsapp;

  UserRegistrationData({
    required this.id,
    required this.nama,
    required this.email,
    required this.tanggalRegistrasi,
    required this.statusAkun,
    required this.totalPeminjaman,
    this.noWhatsapp,
  });
}

class ActiveLoanData {
  final String id;
  final String userName;
  final String userPhone;
  final String assetName;
  final String type; // Pinjam or Perpanjang
  final String status;
  final DateTime dueDate;
  final bool isNearingDue; // < 3 days

  ActiveLoanData({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.assetName,
    required this.type,
    required this.status,
    required this.dueDate,
    required this.isNearingDue,
  });
}

class DashboardProvider extends ChangeNotifier {
  DashboardMetrics? _metrics;
  List<UserRegistrationData> _users = [];
  List<ActiveLoanData> _activeLoans = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  RealtimeChannel? _dashboardRealtimeChannel;
  bool _isSilentRefreshing = false;

  DashboardMetrics? get metrics => _metrics;
  List<UserRegistrationData> get users => _users;
  List<ActiveLoanData> get activeLoans => _activeLoans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic> _toStringKeyMap(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final map = <String, dynamic>{};
    raw.forEach((key, value) {
      map[key.toString()] = value;
    });
    return map;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void startRealtimeUpdates() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchDashboardData(silent: true);
      // Optional: Admin might want periodic overdue checks
      // but usually once per session or on demand is enough
    });

    _startDashboardRealtime();
  }

  void stopRealtimeUpdates() {
    _refreshTimer?.cancel();

    final channel = _dashboardRealtimeChannel;
    if (channel != null) {
      SupabaseService.client.removeChannel(channel);
      _dashboardRealtimeChannel = null;
    }
  }

  void _triggerSilentRefresh() {
    if (_isSilentRefreshing) return;
    _isSilentRefreshing = true;
    fetchDashboardData(silent: true).whenComplete(() {
      _isSilentRefreshing = false;
    });
  }

  void _startDashboardRealtime() {
    if (_dashboardRealtimeChannel != null) return;

    _dashboardRealtimeChannel = SupabaseService.client
        .channel('dashboard-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'peminjaman',
          callback: (_) => _triggerSilentRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'peminjaman',
          callback: (_) => _triggerSilentRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'peminjaman',
          callback: (_) => _triggerSilentRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'perpanjangan',
          callback: (_) => _triggerSilentRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'perpanjangan',
          callback: (_) => _triggerSilentRefresh(),
        )
        .subscribe();
  }

  Future<void> fetchDashboardData({bool silent = false}) async {
    if (!silent) _setLoading(true);
    try {
      // Mulai semua request secara paralel agar waktu tunggu total lebih singkat.
      final activeLoansFuture = _fetchActiveLoanData();
      final usersFuture = _fetchUserRegistrationData();
      final activeLoansCountFuture = _fetchActiveLoansCount();
      final extensionDataFuture = _fetchExtensionStats();
      final statusBreakdownFuture = _fetchStatusBreakdown();
      final usageStatsFuture = _fetchUsageStats();

      // Prioritaskan tabel peminjaman aktif supaya cepat tampil saat halaman dibuka.
      _activeLoans = await activeLoansFuture;
      notifyListeners();

      final users = await usersFuture;
      final activeLoansCount = await activeLoansCountFuture;
      final extensionData = await extensionDataFuture;
      final statusBreakdown = await statusBreakdownFuture;
      final usageStats = await usageStatsFuture;

      _users = users;
      _metrics = DashboardMetrics(
        activeLoans: activeLoansCount,
        totalExtensions: extensionData['total'] as int,
        extensionTrend: extensionData['trend'] as double,
        transactionStatus: statusBreakdown,
        usageStats: usageStats,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<int> _fetchActiveLoansCount() async {
    final res = await SupabaseService.table(
      'peminjaman',
    ).select('id').eq('status', 'disetujui');
    return (res as List).length;
  }

  Future<Map<String, dynamic>> _fetchExtensionStats() async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    final currentRes = await SupabaseService.table('perpanjangan')
        .select('id')
        .eq('status', 'disetujui')
        .gte('created_at', lastMonth.toIso8601String());

    final total = (currentRes as List).length;

    // Simple trend calculation (comparing to previous 30 days)
    final prevMonthStart = now.subtract(const Duration(days: 60));
    final prevRes = await SupabaseService.table('perpanjangan')
        .select('id')
        .eq('status', 'disetujui')
        .gte('created_at', prevMonthStart.toIso8601String())
        .lt('created_at', lastMonth.toIso8601String());

    final prevTotal = (prevRes as List).length;
    double trend = 0;
    if (prevTotal > 0) {
      trend = ((total - prevTotal) / prevTotal) * 100;
    } else if (total > 0) {
      trend = 100;
    }

    return {'total': total, 'trend': trend};
  }

  Future<Map<String, int>> _fetchStatusBreakdown() async {
    final res = await SupabaseService.table('peminjaman').select('status');
    final Map<String, int> counts = {};
    for (var item in (res as List)) {
      final status = item['status'] as String;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<DailyStats>> _fetchUsageStats() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final res = await SupabaseService.table(
      'peminjaman',
    ).select('created_at').gte('created_at', sevenDaysAgo.toIso8601String());

    final Map<String, int> dailyCounts = {};
    for (var item in (res as List)) {
      final date = DateTime.parse(
        item['created_at'],
      ).toIso8601String().split('T')[0];
      dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
    }

    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dateStr = date.toIso8601String().split('T')[0];
      return DailyStats(date, dailyCounts[dateStr] ?? 0);
    });
  }

  Future<List<UserRegistrationData>> _fetchUserRegistrationData() async {
    // Joining users and peminjaman would be better but let's do it simply
    final usersRes = await SupabaseService.table('users').select();
    final loansRes = await SupabaseService.table(
      'peminjaman',
    ).select('user_id');

    final Map<String, int> loanCounts = {};
    for (var loan in (loansRes as List)) {
      final userId = loan['user_id'] as String;
      loanCounts[userId] = (loanCounts[userId] ?? 0) + 1;
    }

    return (usersRes as List).map((u) {
      return UserRegistrationData(
        id: u['id'] ?? '',
        nama: u['nama'] ?? '',
        email: u['email'] ?? 'N/A', // Assuming email is stored in users table
        tanggalRegistrasi:
            DateTime.tryParse(u['created_at'] ?? '') ?? DateTime.now(),
        statusAkun: 'user',
        totalPeminjaman: loanCounts[u['id']] ?? 0,
        noWhatsapp: u['no_whatsapp'],
      );
    }).toList();
  }

  Future<List<ActiveLoanData>> _fetchActiveLoanData() async {
    final loansRes = await SupabaseService.table('peminjaman')
        .select(
          'id, user_id, barang_id, status, rencana_kembali, '
          'users:users!peminjaman_user_id_fkey(nama, no_whatsapp), '
          'barang:barang!peminjaman_barang_id_fkey(nama_barang)',
        )
        .eq('status', 'disetujui');

    final extensionsRes = await SupabaseService.table(
      'perpanjangan',
    ).select('peminjaman_id').eq('status', 'disetujui');

    final extendedLoanIds = (extensionsRes as List)
        .map((e) => e['peminjaman_id'] as String)
        .toSet();

    final loans = loansRes as List;

    // Fallback hanya untuk baris yang join-nya benar-benar kosong.
    final missingUserIds = <String>{};
    final missingItemIds = <String>{};

    for (final l in loans) {
      final joinedUser = _toStringKeyMap(l['users']);
      final joinedItem = _toStringKeyMap(l['barang']);

      final userId = l['user_id']?.toString();
      final itemId = l['barang_id']?.toString();

      if (joinedUser.isEmpty && userId != null && userId.isNotEmpty) {
        missingUserIds.add(userId);
      }
      if (joinedItem.isEmpty && itemId != null && itemId.isNotEmpty) {
        missingItemIds.add(itemId);
      }
    }

    final Map<String, Map<String, dynamic>> usersById = {};
    if (missingUserIds.isNotEmpty) {
      final usersRes = await SupabaseService.table('users')
          .select('id, nama, no_whatsapp')
          .inFilter('id', missingUserIds.toList());
      for (final raw in (usersRes as List)) {
        final row = _toStringKeyMap(raw);
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) {
          usersById[id] = row;
        }
      }
    }

    final Map<String, Map<String, dynamic>> itemsById = {};
    if (missingItemIds.isNotEmpty) {
      final itemsRes = await SupabaseService.table('barang')
          .select('id, nama_barang')
          .inFilter('id', missingItemIds.toList());
      for (final raw in (itemsRes as List)) {
        final row = _toStringKeyMap(raw);
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) {
          itemsById[id] = row;
        }
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return loans.map((l) {
      final dueDate = DateTime.tryParse(l['rencana_kembali'] ?? '') ?? now;
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final diffDays = dueDateOnly.difference(today).inDays;
      final isNearingDue = diffDays >= 0 && diffDays < 3;

      final userId = l['user_id'] as String?;
      final itemId = l['barang_id'] as String?;
        final joinedUser = _toStringKeyMap(l['users']);
        final joinedItem = _toStringKeyMap(l['barang']);

      final fallbackUser = userId != null ? usersById[userId] : null;
      final fallbackItem = itemId != null ? itemsById[itemId] : null;

        final userName = (joinedUser['nama'] ?? fallbackUser?['nama'] ?? 'Unknown')
          .toString();
        final userPhone =
          (joinedUser['no_whatsapp'] ?? fallbackUser?['no_whatsapp'] ?? 'N/A')
            .toString();
        final assetName =
          (joinedItem['nama_barang'] ?? fallbackItem?['nama_barang'] ?? 'Unknown')
            .toString();

      return ActiveLoanData(
        id: l['id'] ?? '',
        userName: userName.toString().isNotEmpty ? userName.toString() : 'Unknown',
        userPhone: userPhone.toString().isNotEmpty ? userPhone.toString() : 'N/A',
        assetName: assetName.toString().isNotEmpty ? assetName.toString() : 'Unknown',
        type: extendedLoanIds.contains(l['id']) ? 'Perpanjang' : 'Pinjam',
        status: (l['status'] ?? 'disetujui').toString(),
        dueDate: dueDate,
        isNearingDue: isNearingDue,
      );
    }).toList();
  }

  @override
  void dispose() {
    stopRealtimeUpdates();
    super.dispose();
  }
}
