import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:csv/csv.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/approval_provider.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboard = context.read<DashboardProvider>();
      dashboard.fetchDashboardData();
      dashboard.startRealtimeUpdates();
      context.read<InventoryProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    // DashboardProvider real-time updates are handled in its own lifecycle if possible,
    // but here we should probably stop it when this page is not visible.
    // However, DashboardAdminPage is likely a main tab.
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: SafeArea(
        child: ScreenTypeLayout.builder(
          mobile: (context) => _buildMobileLayout(context),
          tablet: (context) => _buildTabletLayout(context),
          desktop: (context) => _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().fetchDashboardData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMetricGrid(crossAxisCount: 2),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            _buildActiveLoansTableSection(),
            const SizedBox(height: 80), // Space for navbar
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMetricGrid(crossAxisCount: 2),
          const SizedBox(height: 24),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          _buildActiveLoansTableSection(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMetricGrid(crossAxisCount: 4),
          const SizedBox(height: 24),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          _buildActiveLoansTableSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MANAJEMEN ASET',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA3AED0),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Inventaris',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
              ),
            ),
            _buildExportButtons(),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.description_outlined,
          label: 'Excel',
          onPressed: _exportToExcel,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.grid_on_outlined,
          label: 'CSV',
          onPressed: _exportToCSV,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              icon: Icon(Icons.search, color: Color(0xFFA3AED0)),
              hintText: 'Cari nama aset, SKU, atau kategori...',
              hintStyle: TextStyle(color: Color(0xFFA3AED0), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFilterButton(
              label: 'Kondisi',
              icon: Icons.category_outlined,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              label: 'Terbaru',
              icon: Icons.sort,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF4F7FE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2B3674)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B3674),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Color(0xFFA3AED0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid({required int crossAxisCount}) {
    final dashboard = context.watch<DashboardProvider>();
    final inventory = context.watch<InventoryProvider>();

    if (dashboard.isLoading && dashboard.metrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalItems = inventory.items.length;
    final baikCount = inventory.items
        .where((i) => i.kondisiBarang.toLowerCase() == 'baik')
        .length;
    final rusakCount = inventory.items
        .where((i) => i.kondisiBarang.toLowerCase() == 'rusak')
        .length;
    final dipinjamCount = dashboard.activeLoans.length;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio:
          1.0, // Changed to 1.0 for more square-like cards as in image
      children: [
        _buildMetricCard(
          title: 'TOTAL ITEM',
          value: totalItems.toString(),
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF2B3674),
        ),
        _buildMetricCard(
          title: 'KONDISI BAIK',
          value: baikCount.toString(),
          icon: Icons.check_circle_outline,
          color: const Color(0xFF05CD99),
        ),
        _buildMetricCard(
          title: 'DIPINJAM',
          value: dipinjamCount.toString(),
          icon: Icons.access_time,
          color: const Color(0xFFFFB547),
        ),
        _buildMetricCard(
          title: 'RUSAK',
          value: rusakCount.toString(),
          icon: Icons.build_outlined,
          color: const Color(0xFFEE5D50),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFA3AED0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLoansTableSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peminjaman Aktif (Nearing Due)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B3674),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 400, child: _buildActiveLoansTable()),
        ],
      ),
    );
  }

  Widget _buildActiveLoansTable() {
    final dashboard = context.watch<DashboardProvider>();
    final loans = dashboard.activeLoans;

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 600,
      columns: [
        const DataColumn2(label: Text('USER'), size: ColumnSize.L),
        const DataColumn2(label: Text('ASET'), size: ColumnSize.L),
        const DataColumn2(label: Text('TIPE'), size: ColumnSize.S),
        const DataColumn2(label: Text('<3 HARI'), size: ColumnSize.S),
      ],
      rows: loans.map((loan) {
        return DataRow(
          cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(
                          0xFF4318FF,
                        ).withValues(alpha: 0.1),
                        child: Text(
                          loan.userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4318FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loan.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B3674),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 36.0),
                    child: Text(
                      loan.userPhone,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFA3AED0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                loan.assetName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  loan.type,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA3AED0),
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                DateFormat('dd MMM yyyy').format(loan.dueDate),
                style: TextStyle(
                  color: loan.isNearingDue
                      ? Colors.red
                      : const Color(0xFF2B3674),
                  fontWeight: loan.isNearingDue
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _exportToExcel() async {
    final dashboard = context.read<DashboardProvider>();
    var excel = excel_lib.Excel.createExcel();
    var sheet = excel['Dashboard Data'];

    sheet.appendRow([
      excel_lib.TextCellValue('ID User'),
      excel_lib.TextCellValue('Nama Lengkap'),
      excel_lib.TextCellValue('Email'),
      excel_lib.TextCellValue('Tanggal Registrasi'),
      excel_lib.TextCellValue('Status Akun'),
      excel_lib.TextCellValue('Total Peminjaman'),
    ]);

    for (var user in dashboard.users) {
      sheet.appendRow([
        excel_lib.TextCellValue(user.id),
        excel_lib.TextCellValue(user.nama),
        excel_lib.TextCellValue(user.email),
        excel_lib.TextCellValue(user.tanggalRegistrasi.toIso8601String()),
        excel_lib.TextCellValue(user.statusAkun),
        excel_lib.IntCellValue(user.totalPeminjaman),
      ]);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'dashboard_export_$timestamp.xlsx';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File diekspor ke ${file.path}')));
      await OpenFilex.open(file.path);
    }
  }

  Future<void> _exportToCSV() async {
    final dashboard = context.read<DashboardProvider>();
    List<List<dynamic>> rows = [];
    rows.add([
      "ID User",
      "Nama Lengkap",
      "Email",
      "Tanggal Registrasi",
      "Status Akun",
      "Total Peminjaman",
    ]);

    for (var user in dashboard.users) {
      rows.add([
        user.id,
        user.nama,
        user.email,
        user.tanggalRegistrasi.toIso8601String(),
        user.statusAkun,
        user.totalPeminjaman,
      ]);
    }

    String csvContent = CsvEncoder().convert(rows);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'dashboard_export_$timestamp.csv';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvContent);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('File diekspor ke ${file.path}')));
    await OpenFilex.open(file.path);
  }
}
