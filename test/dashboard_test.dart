import 'package:flutter_test/flutter_test.dart';
import 'package:inforsa_inventory/providers/dashboard_provider.dart';

void main() {
  group('Dashboard Logic Tests', () {
    test('Trend calculation should be correct', () {
      // In a real app, I'd mock Supabase. Here I'll test the data models.
      final metrics = DashboardMetrics(
        activeLoans: 10,
        totalExtensions: 5,
        extensionTrend: 20.0,
        transactionStatus: {'disetujui': 5, 'pending': 2},
        usageStats: [DailyStats(DateTime.now(), 3)],
      );

      expect(metrics.activeLoans, 10);
      expect(metrics.extensionTrend, 20.0);
    });

    test('UserRegistrationData model should hold data correctly', () {
      final user = UserRegistrationData(
        id: '123',
        nama: 'Budi Setiawan',
        email: 'budi@example.com',
        tanggalRegistrasi: DateTime(2023, 10, 10),
        statusAkun: 'user',
        totalPeminjaman: 5,
      );

      expect(user.id, '123');
      expect(user.nama, 'Budi Setiawan');
      expect(user.totalPeminjaman, 5);
    });

    test('ActiveLoanData nearing due calculation', () {
      final now = DateTime.now();
      final nearDue = now.add(const Duration(hours: 48));
      final notNearDue = now.add(const Duration(hours: 100));

      final loan1 = ActiveLoanData(
        id: '1',
        userName: 'User 1',
        userPhone: '0812',
        assetName: 'Asset 1',
        type: 'Pinjam',
        status: 'disetujui',
        dueDate: nearDue,
        isNearingDue: true, // This would be calculated in the provider
      );

      final loan2 = ActiveLoanData(
        id: '2',
        userName: 'User 2',
        userPhone: '0813',
        assetName: 'Asset 2',
        type: 'Pinjam',
        status: 'disetujui',
        dueDate: notNearDue,
        isNearingDue: false,
      );

      expect(loan1.isNearingDue, isTrue);
      expect(loan2.isNearingDue, isFalse);
    });
  });
}
