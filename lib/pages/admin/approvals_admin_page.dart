import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/approval_provider.dart';
import 'approval_tabs/apr_peminjaman.dart';
import 'approval_tabs/apr_perpanjangan.dart';
import 'approval_tabs/apr_pengembalian.dart';

class ApprovalsAdminPage extends StatefulWidget {
  const ApprovalsAdminPage({super.key});

  @override
  State<ApprovalsAdminPage> createState() => _ApprovalsAdminPageState();
}

class _ApprovalsAdminPageState extends State<ApprovalsAdminPage> {
  ApprovalProvider? _approvalProvider;

  @override
  void initState() {
    super.initState();
    _approvalProvider = context.read<ApprovalProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAll();
      if (!mounted) return;
      await _approvalProvider?.startAdminApprovalRealtime();
    });
  }

  @override
  void dispose() {
    _approvalProvider?.stopAdminApprovalRealtime();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await (_approvalProvider ?? context.read<ApprovalProvider>())
        .fetchAllForAdmin();
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF1E1E45);
    final approval = context.watch<ApprovalProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TabBar(
                indicatorColor: navyColor,
                indicatorWeight: 3,
                labelColor: navyColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  _buildTab(
                    Icons.calendar_today_outlined,
                    'PEMINJAMAN',
                    approval.pendingPeminjaman.length,
                  ),
                  _buildTab(
                    Icons.access_time,
                    'PERPANJANGAN',
                    approval.pendingPerpanjangan.length,
                  ),
                  _buildTab(
                    Icons.assignment_return_outlined,
                    'PENGEMBALIAN',
                    approval.pendingPengembalian.length,
                  ),
                ],
              ),
            ),
            Expanded(
              child: approval.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        AprPeminjamanTab(onRefresh: _loadAll),
                        AprPerpanjanganTab(onRefresh: _loadAll),
                        AprPengembalianTab(onRefresh: _loadAll),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Tab _buildTab(IconData icon, String label, int count) {
    return Tab(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
