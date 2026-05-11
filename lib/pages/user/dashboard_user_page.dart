import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../widgets/inforsa_header.dart';
import '../../providers/approval_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/peminjaman_model.dart';
import 'detail_item_page.dart';
import 'forms/perpanjangan_page.dart';

class DashboardUserPage extends StatefulWidget {
  const DashboardUserPage({super.key});

  @override
  State<DashboardUserPage> createState() => _DashboardUserPageState();
}

class _DashboardUserPageState extends State<DashboardUserPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<ApprovalProvider>().fetchUserPeminjaman(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final approval = context.watch<ApprovalProvider>();
    final user = auth.currentUser;

    final aktif = approval.peminjaman
        .where((p) => p.isDisetujui && !p.isTerlambat)
        .toList();
    final menunggu = approval.peminjaman.where((p) => p.isMenunggu).toList();
    final terlambat = approval.terlambat;

<<<<<<< HEAD
=======
    // Tampilkan hanya data barang dengan status "dipinjam" milik user yang login dan masih dalam rentang tanggal peminjaman
>>>>>>> 190e2f40caab643be0b09682bd87d23eac3662a1
    final peminjamanAktif = approval.peminjaman
        .where(
          (p) =>
              p.status == 'disetujui' &&
              DateTime.now().isBefore(p.rencanakembali),
        )
        .toList();

    // Filter search
    final filtered = _searchQuery.isEmpty
        ? peminjamanAktif
        : peminjamanAktif
              .where(
                (p) =>
                    (p.namaBarang ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (p.kodeBarang ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const InforsaHeader(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Selamat datang, ${user?.nama.split(' ').first ?? 'User'}.',
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kelola aset dan permintaan peminjaman Anda di satu tempat.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Summary card — Peminjaman Aktif
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A0A0A), Color(0xFF1A1F35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PEMINJAMAN AKTIF',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          aktif.length.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Aset',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${terlambat.length} mendekati jatuh tempo',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (aktif.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailItemPage(peminjaman: aktif.first),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Lihat Detail',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Summary cards — Menunggu & Jatuh Tempo 
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7E5FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.pending_actions,
                              color: Color(0xFF4A72FF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MENUNGGU',
                            style: TextStyle(
                              color: Color(0xFF6B80A6),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            menunggu.length.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Permintaan diproses',
                            style: TextStyle(
                              color: Color(0xFF5A729B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              color: Color(0xFFD92D20),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'JATUH TEMPO',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            terlambat.length.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Color(0xFFD92D20),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Segera kembalikan',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBECEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    icon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    hintText: 'Cari aset yang dipinjam...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Peminjaman Saat Ini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tabel Peminjaman Aktif (Redesign)
              _buildPeminjamanTable(filtered),

              if (!_showAllHistory && filtered.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(() => _showAllHistory = true),
                      child: const Text(
                        'Tampilkan Lebih Banyak',
                        style: TextStyle(
                          color: Color(0xFF4318FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeminjamanTable(List<PeminjamanModel> allData) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    // Filter: < 3 hari sebelum jatuh tempo jika tidak show all
    final now = DateTime.now();
    List<PeminjamanModel> displayData = allData;

    if (!_showAllHistory) {
      displayData = allData.where((p) {
        final daysLeft = p.rencanakembali.difference(now).inDays;
        return daysLeft < 3;
      }).toList();

      if (displayData.length > 5) {
        displayData = displayData.take(5).toList();
      }
    } else {
      // Saat Tampilkan Lebih Banyak, tampilkan seluruh barang yang pernah dipinjam user
      final approval = context.watch<ApprovalProvider>();
      displayData = approval.peminjaman;
    }

    if (displayData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Tidak ada data peminjaman')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: ((displayData.length + 1) * 56.0).clamp(180.0, 420.0),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 500,
          columns: const [
            DataColumn2(label: Text('BARANG'), size: ColumnSize.L),
            DataColumn2(label: Text('TIPE'), size: ColumnSize.S),
            DataColumn2(label: Text('<3 HARI'), size: ColumnSize.M),
            DataColumn2(label: Text('AKSI'), size: ColumnSize.S),
          ],
          rows: displayData.map((p) {
            final isPerpanjangan = p.status == 'menunggu_konfirmasi';
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.namaBarang ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B3674),
                        ),
                      ),
                      Text(
                        '${user?.nama} | ${user?.noWhatsapp}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFA3AED0),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPerpanjangan ? 'Perpanjang' : 'Pinjam',
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
                    DateFormat('dd Okt yyyy', 'id').format(p.rencanakembali),
                    style: const TextStyle(
                      color: Color(0xFF2B3674),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.history_outlined, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PerpanjanganPage(peminjaman: p),
                        ),
                      ).then((value) {
                        if (value == true) {
                          _loadData();
                        }
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
