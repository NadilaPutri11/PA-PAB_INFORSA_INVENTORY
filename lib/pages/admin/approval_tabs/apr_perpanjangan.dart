// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/pages/admin/approval_tabs/apr_perpanjangan.dart
// FIX: Hapus initState fetch — data sudah di-fetch oleh ApprovalsAdminPage
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/approval_provider.dart';
import '../../../models/perpanjangan_model.dart';

class AprPerpanjanganTab extends StatelessWidget {
  // FIX: Terima callback refresh dari parent
  final Future<void> Function() onRefresh;

  const AprPerpanjanganTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final approval = context.watch<ApprovalProvider>();
    final fmt = DateFormat('dd MMM yyyy', 'id');

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Persetujuan Perpanjangan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Review permintaan perpanjangan peminjaman. Evaluasi alasan dan durasi tambahan sebelum menyetujui.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),

          if (approval.perpanjangan.isEmpty)
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
                      'Tidak ada permintaan perpanjangan',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            // FIX: Tampilkan semua tapi bedakan visual pending vs sudah diproses
            ...approval.perpanjangan.map(
              (p) => _buildCard(context, p, approval, fmt),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    PerpanjanganModel p,
    ApprovalProvider approval,
    DateFormat fmt,
  ) {
    final isPending = p.status == 'menunggu';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // FIX: Beri visual berbeda untuk yang sudah diproses
        border: !isPending ? Border.all(color: Colors.grey.shade200) : null,
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'DIMINTA OLEH',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const Spacer(),
                        // FIX: Tampilkan badge status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFEF3C7)
                                : p.status == 'disetujui'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPending
                                ? 'MENUNGGU'
                                : p.status == 'disetujui'
                                ? 'DISETUJUI'
                                : 'DITOLAK',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: isPending
                                  ? const Color(0xFFD97706)
                                  : p.status == 'disetujui'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      p.peminjaman?.namaUser ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.peminjaman?.namaBarang ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: p.peminjaman?.rencanakembali != null
                                      ? 'Saat ini: ${fmt.format(p.peminjaman!.rencanakembali)}  →  '
                                      : '',
                                ),
                                TextSpan(
                                  text: fmt.format(p.tanggalJatuhTempoBaru),
                                  style: const TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (p.alasanPerpanjangan != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${p.alasanPerpanjangan}"',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // FIX: Tombol hanya muncul kalau masih pending
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, p, approval, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, p, approval, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF114376),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Setujui',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    PerpanjanganModel p,
    ApprovalProvider approval,
    bool setujui,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(setujui ? 'Setujui Perpanjangan' : 'Tolak Perpanjangan'),
        content: Text(
          setujui ? 'Setujui perpanjangan ini?' : 'Tolak perpanjangan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: setujui ? const Color(0xFF114376) : Colors.red,
            ),
            child: Text(
              setujui ? 'Setujui' : 'Tolak',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    bool success = false;

    if (setujui) {
      // Update status di tabel perpanjangan → 'disetujui'
      // Update tanggal rencana kembali di tabel peminjaman sekaligus
      success = await approval.updateStatusPerpanjangan(
        perpanjanganId: p.id,
        status: 'disetujui',
        peminjamanId: p.peminjaman?.id,
        tanggalBaruKembali: p.tanggalJatuhTempoBaru,
      );
    } else {
      // Update status di tabel perpanjangan → 'ditolak'
      success = await approval.updateStatusPerpanjangan(
        perpanjanganId: p.id,
        status: 'ditolak',
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (setujui ? 'Perpanjangan disetujui!' : 'Perpanjangan ditolak')
              : 'Gagal memproses perpanjangan',
        ),
        backgroundColor: success
            ? (setujui ? Colors.green : Colors.orange)
            : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (success) await onRefresh();
  }
}
