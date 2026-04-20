// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/pages/admin/approval_tabs/apr_peminjaman.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/approval_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../models/peminjaman_model.dart';

class AprPeminjamanTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AprPeminjamanTab({super.key, required this.onRefresh});

  @override
  State<AprPeminjamanTab> createState() => _AprPeminjamanTabState();
}

class _AprPeminjamanTabState extends State<AprPeminjamanTab> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final approval = context.watch<ApprovalProvider>();

    // Menampilkan permohonan yang menunggu keputusan admin
    final pendingList = approval.pendingPeminjaman;
    final fmt = DateFormat('dd MMM yyyy', 'id');

    // Kalkulasi Pagination
    final int totalPages = (pendingList.length / _itemsPerPage).ceil();
    int displayPage = (_currentPage > totalPages && totalPages > 0)
        ? 1
        : _currentPage;

    // Memotong data sesuai halaman saat ini
    final paginatedItems = pendingList.isEmpty
        ? <PeminjamanModel>[]
      : pendingList
              .skip((displayPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          const Text(
            'APPROVALS',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Peminjaman',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Berikut adalah daftar permohonan peminjaman yang menunggu persetujuan admin.',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 32),

          if (pendingList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada permohonan menunggu persetujuan',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...paginatedItems.map(
              (p) => _buildPendingPeminjamanCard(context, p, approval, fmt),
            ),

          if (totalPages > 1) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                int pageNum = index + 1;
                bool isSelected = pageNum == displayPage;
                if (totalPages > 5 && pageNum > 3 && pageNum != totalPages) {
                  if (pageNum == 4) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => setState(() => _currentPage = pageNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        pageNum.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  IconData _getIconFor(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('laptop') || n.contains('macbook') || n.contains('komputer')) {
      return Icons.laptop_mac;
    }
    if (n.contains('camera') || n.contains('kamera') || n.contains('alpha')) {
      return Icons.camera_alt_outlined;
    }
    if (n.contains('stempel')) {
      return Icons.approval;
    }
    return Icons.inventory_2_outlined;
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => Container(
                color: Colors.white,
                padding: const EdgeInsets.all(32),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPeminjamanCard(
    BuildContext context,
    PeminjamanModel p,
    ApprovalProvider approval,
    DateFormat fmt,
  ) {
    final durasi = p.rencanakembali.difference(p.tanggalPinjam).inDays;
    final displayDurasi = durasi <= 0 ? 1 : durasi;

    // Memecah URL gabungan jika ada koma (karena 2 foto disatukan)
    final imageUrls = p.fotoSebelumPinjamUrl?.isNotEmpty == true
        ? p.fotoSebelumPinjamUrl!.split(',')
        : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconFor(p.namaBarang ?? ''),
                  color: const Color(0xFF1E3A8A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PERMOHONAN DARI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E3A8A),
                            letterSpacing: 1.0,
                          ),
                        ),
                        // Badge Status Dinamis (Berlangsung / Jatuh Tempo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'MENUNGGU',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.namaUser ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.namaBarang ?? '-'} - SKU: ${p.kodeBarang ?? '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${fmt.format(p.tanggalPinjam)} — ${fmt.format(p.rencanakembali)}\n($displayDurasi Hari)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_android_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.noWhatsappUser ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.subject, size: 16, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"${p.alasanMeminjam ?? '-'}"',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'FOTO KONDISI AWAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          // --- MENAMPILKAN 2 FOTO ---
          Row(
            children: [
              Expanded(
                child: _buildImageThumbnail(
                  imageUrls.isNotEmpty ? imageUrls[0] : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImageThumbnail(
                  imageUrls.length > 1 ? imageUrls[1] : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap foto untuk memperbesar',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: approval.isLoading
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Tolak Peminjaman'),
                              content: Text('Tolak permohonan dari ${p.namaUser ?? '-'}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Tolak', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true || !context.mounted) return;
                          final success = await approval.updateStatusPeminjaman(
                            p.id,
                            'ditolak',
                            p.barangId,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Peminjaman ditolak' : 'Gagal menolak peminjaman'),
                              backgroundColor: success ? Colors.orange : Colors.red,
                            ),
                          );
                          if (success) {
                            await widget.onRefresh();
                            if (context.mounted) {
                              await context.read<DashboardProvider>().fetchDashboardData(silent: true);
                            }
                          }
                        },
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: approval.isLoading
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Setujui Peminjaman'),
                              content: Text('Setujui permohonan dari ${p.namaUser ?? '-'}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF114376)),
                                  child: const Text('Setujui', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true || !context.mounted) return;
                          final success = await approval.updateStatusPeminjaman(
                            p.id,
                            'disetujui',
                            p.barangId,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Peminjaman disetujui' : 'Gagal menyetujui peminjaman'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                          if (success) {
                            await widget.onRefresh();
                            if (context.mounted) {
                              await context.read<DashboardProvider>().fetchDashboardData(silent: true);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF114376),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Setujui'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showImageDialog(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            height: 110,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
