import 'dart:async';
import 'package:flutter/material.dart';
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
  final DateTime dueDate;
  final bool isNearingDue; // < 3 days

  ActiveLoanData({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.assetName,
    required this.type,
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

  DashboardMetrics? get metrics => _metrics;
  List<UserRegistrationData> get users => _users;
  List<ActiveLoanData> get activeLoans => _activeLoans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void startRealtimeUpdates() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchDashboardData(silent: true);
    });
  }

  void stopRealtimeUpdates() {
    _refreshTimer?.cancel();
  }

  Future<void> fetchDashboardData({bool silent = false}) async {
    if (!silent) _setLoading(true);
    try {
      // 1. Fetch Metrics
      final activeLoansCount = await _fetchActiveLoansCount();
      final extensionData = await _fetchExtensionStats();
      final statusBreakdown = await _fetchStatusBreakdown();
      final usageStats = await _fetchUsageStats();

      _metrics = DashboardMetrics(
        activeLoans: activeLoansCount,
        totalExtensions: extensionData['total'] as int,
        extensionTrend: extensionData['trend'] as double,
        transactionStatus: statusBreakdown,
        usageStats: usageStats,
      );

      // 2. Fetch User Registration Table Data
      _users = await _fetchUserRegistrationData();

      // 3. Fetch Active Loans for the Table
      _activeLoans = await _fetchActiveLoanData();

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
        statusAkun: u['role'] ?? 'user',
        totalPeminjaman: loanCounts[u['id']] ?? 0,
        noWhatsapp: u['no_whatsapp'],
      );
    }).toList();
  }

  Future<List<ActiveLoanData>> _fetchActiveLoanData() async {
    final loansRes = await SupabaseService.table('peminjaman')
        .select('*, users(nama, no_whatsapp), barang(nama_barang)')
        .eq('status', 'disetujui');

    final extensionsRes = await SupabaseService.table(
      'perpanjangan',
    ).select('peminjaman_id').eq('status', 'disetujui');

    final extendedLoanIds = (extensionsRes as List)
        .map((e) => e['peminjaman_id'] as String)
        .toSet();

    final now = DateTime.now();

    return (loansRes as List).map((l) {
      final dueDate = DateTime.tryParse(l['rencana_kembali'] ?? '') ?? now;
      final diff = dueDate.difference(now).inHours;
      final isNearingDue =
          diff > 0 && diff <= 72; // Less than 72 hours (3 days)

      return ActiveLoanData(
        id: l['id'] ?? '',
        userName: l['users']?['nama'] ?? 'Unknown',
        userPhone: l['users']?['no_whatsapp'] ?? 'N/A',
        assetName: l['barang']?['nama_barang'] ?? 'Unknown',
        type: extendedLoanIds.contains(l['id']) ? 'Perpanjang' : 'Pinjam',
        dueDate: dueDate,
        isNearingDue: isNearingDue,
      );
    }).toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
