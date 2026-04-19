import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/approval_provider.dart';
import '../../models/peminjaman_model.dart';
import '../../widgets/inforsa_header.dart';

import 'forms/pengembalian_page.dart';
import 'forms/perpanjangan_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Peminjaman', 'Pengembalian', 'Perpanjangan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<ApprovalProvider>().fetchUserPeminjaman(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final approval = context.watch<ApprovalProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const InforsaHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isActive = _selectedFilterIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : const Color(0xFFF1F2F4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: approval.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildContent(approval),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ApprovalProvider approval) {
    switch (_selectedFilterIndex) {
      case 0:
        return _buildPeminjamanView(approval);
      case 1:
        return _buildPengembalianView(approval);
      case 2:
        return _buildPerpanjanganView(approval);
      default:
        return _buildPeminjamanView(approval);
    }
  }

  // ── Tab Peminjaman ──────────────────────────────────────────────────────────
  Widget _buildPeminjamanView(ApprovalProvider approval) {
    final aktifList = approval.activePeminjaman;

    if (aktifList.isEmpty) {
      return _buildEmptyState(
        Icons.inventory_2_outlined,
        'Tidak ada aset yang sedang dipinjam',
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Pinjaman Aktif (${aktifList.length.toString().padLeft(2, '0')})',
          ),
          const SizedBox(height: 16),
          ...aktifList.map((p) => _buildPinjamanCard(p)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Tab Pengembalian ────────────────────────────────────────────────────────
  Widget _buildPengembalianView(ApprovalProvider approval) {
    final menungguKonfirmasi = approval.peminjaman
        .where((p) => p.status == 'menunggu_konfirmasi')
        .toList();
    final selesaiList = approval.peminjaman.where((p) => p.isSelesai).toList();

    if (menungguKonfirmasi.isEmpty && selesaiList.isEmpty) {
      return _buildEmptyState(
        Icons.assignment_return_outlined,
        'Belum ada riwayat pengembalian',
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (menungguKonfirmasi.isNotEmpty) ...[
            _buildSectionHeader('Menunggu Konfirmasi Admin'),
            const SizedBox(height: 16),
            ...menungguKonfirmasi.map((p) => _buildKonfirmasiCard(p)),
            const SizedBox(height: 32),
          ],
          if (selesaiList.isNotEmpty) ...[
            _buildSectionHeader('Selesai'),
            const SizedBox(height: 16),
            ...selesaiList.map((p) => _buildSelesaiCard(p)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPerpanjanganView(ApprovalProvider approval) {
    final bisaDiperpanjang = approval.activePeminjaman;

    if (bisaDiperpanjang.isEmpty) {
      return _buildEmptyState(
        Icons.history,
        'Tidak ada peminjaman aktif yang bisa diperpanjang',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: bisaDiperpanjang.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildPerpanjanganCard(bisaDiperpanjang[index]),
    );
  }

  // ── Card Builder Helpers (Sekarang di dalam Class State) ────────────────────

  Widget _buildKonfirmasiCard(PeminjamanModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF15803D).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: Color(0xFF15803D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEDANG DICEK ADMIN',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.namaBarang ?? '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'Mohon tunggu konfirmasi kondisi aset...',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinjamanCard(PeminjamanModel p) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    final durasi = p.rencanakembali.difference(p.tanggalPinjam).inDays;
    final displayDurasi = durasi <= 0 ? 1 : durasi;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final returnDate = DateTime(
      p.rencanakembali.year,
      p.rencanakembali.month,
      p.rencanakembali.day,
    );

    final isOverdue = today.isAfter(returnDate);
    final statusText = isOverdue ? 'JATUH TEMPO' : 'BERLANGSUNG';
    final statusColor = isOverdue
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final statusBg = isOverdue
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BORROWED',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${p.namaBarang ?? '-'} - SKU: ${p.kodeBarang ?? '-'}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                '${fmt.format(p.tanggalPinjam)} — ${fmt.format(p.rencanakembali)} ($displayDurasi Hari)',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PengembalianPage(peminjaman: p),
                      ),
                    );
                    if (result == true && mounted) _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Kembalikan',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerpanjanganPage(peminjaman: p),
                      ),
                    );
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDBEAFE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Perpanjang',
                    style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelesaiCard(PeminjamanModel p) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.namaBarang ?? '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Selesai pada ${p.updatedAt != null ? fmt.format(p.updatedAt!) : '-'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerpanjanganCard(PeminjamanModel p) {
    return _buildPinjamanCard(p);
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    );
  }
}
