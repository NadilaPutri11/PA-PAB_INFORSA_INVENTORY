import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/approval_provider.dart';
import '../../../models/pengembalian_model.dart';

class AprPengembalianTab extends StatelessWidget {
  // FIX: Terima callback refresh dari parent
  final Future<void> Function() onRefresh;

  const AprPengembalianTab({super.key, required this.onRefresh});

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
            'Persetujuan Pengembalian',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Verifikasi pengembalian aset dan kondisi barang untuk menyelesaikan proses peminjaman.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),

          if (approval.pengembalian.isEmpty)
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
                      'Tidak ada pengembalian menunggu',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...approval.pengembalian.map(
              (p) => _buildCard(context, p, approval, fmt),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    PengembalianModel p,
    ApprovalProvider approval,
    DateFormat fmt,
  ) {
    final isPending = p.status == 'menunggu_konfirmasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  Icons.assignment_return_outlined,
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
                          'DIKEMBALIKAN OLEH',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const Spacer(),
                        // FIX: Badge status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPending ? 'MENUNGGU' : 'SELESAI',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: isPending
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A),
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

                    if (p.tanggalDikembalikan != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dikembalikan: ${fmt.format(p.tanggalDikembalikan!)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                    if (p.catatanPengembalian != null &&
                        p.catatanPengembalian!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '"${p.catatanPengembalian}"',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Foto kondisi
                    if (p.fotoKembaliDepanUrl != null ||
                        p.fotoKembaliBelakangUrl != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'FOTO KONDISI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (p.fotoKembaliDepanUrl != null)
                            Expanded(
                              child: GestureDetector(
                                // FIX: Tap foto untuk lihat fullscreen
                                onTap: () => _showFotoFullscreen(
                                  context,
                                  p.fotoKembaliDepanUrl!,
                                  'Foto Depan',
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p.fotoKembaliDepanUrl!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (p.fotoKembaliDepanUrl != null &&
                              p.fotoKembaliBelakangUrl != null)
                            const SizedBox(width: 8),
                          if (p.fotoKembaliBelakangUrl != null)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showFotoFullscreen(
                                  context,
                                  p.fotoKembaliBelakangUrl!,
                                  'Foto Belakang',
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p.fotoKembaliBelakangUrl!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap foto untuk memperbesar',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
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
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: approval.isLoading
                    ? null
                    : () => _handleKonfirmasi(context, p, approval),
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Konfirmasi Penerimaan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF114376),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFotoFullscreen(BuildContext context, String url, String label) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Image.network(url, fit: BoxFit.contain),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleKonfirmasi(
    BuildContext context,
    PengembalianModel p,
    ApprovalProvider approval,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Penerimaan'),
        content: Text(
          'Konfirmasi bahwa ${p.peminjaman?.namaBarang ?? 'barang'} telah diterima kembali?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF114376),
            ),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await approval.updateStatusPengembalian(
      pengembalianId: p.id,
      peminjamanId: p.peminjaman?.id,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pengembalian berhasil dikonfirmasi!'
              : 'Gagal mengkonfirmasi pengembalian',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (success) await onRefresh();
  }
}
