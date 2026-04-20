import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/peminjaman_model.dart';
import '../../services/supabase_service.dart';

class UserActivityDetailPage extends StatefulWidget {
  final String loanId;

  const UserActivityDetailPage({super.key, required this.loanId});

  @override
  State<UserActivityDetailPage> createState() => _UserActivityDetailPageState();
}

class _UserActivityDetailPageState extends State<UserActivityDetailPage> {
  PeminjamanModel? _loanDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetchData();
  }

  Future<void> _checkAccessAndFetchData() async {
    final auth = context.read<AuthProvider>();

    // Middleware: Check if user is admin
    if (!auth.isAdmin) {
      setState(() {
        _error = 'Akses ditolak. Hanya Admin yang dapat mengakses halaman ini.';
        _isLoading = false;
      });
      return;
    }

    try {
      final raw = await SupabaseService.table('peminjaman')
          .select(
            'id, user_id, barang_id, tanggal_pinjam, rencana_kembali, alasan_meminjam, '
            'foto_sebelum_pinjam_url, status, created_at, '
            'users:users!peminjaman_user_id_fkey(nama, departemen, no_whatsapp), '
            'barang:barang!peminjaman_barang_id_fkey(nama_barang, kode_barang)',
          )
          .eq('id', widget.loanId)
          .single();

      Map<String, dynamic> loanMap = Map<String, dynamic>.from(raw as Map);

      final userId = loanMap['user_id']?.toString();
      final barangId = loanMap['barang_id']?.toString();

      final joinedUsers = loanMap['users'];
      if ((joinedUsers == null || (joinedUsers is Map && joinedUsers.isEmpty)) &&
          userId != null &&
          userId.isNotEmpty) {
        try {
          final userData = await SupabaseService.table('users')
              .select('nama, departemen, no_whatsapp')
              .eq('id', userId)
              .single();
          loanMap['users'] = userData;
        } catch (_) {}
      }

      final joinedBarang = loanMap['barang'];
      if ((joinedBarang == null || (joinedBarang is Map && joinedBarang.isEmpty)) &&
          barangId != null &&
          barangId.isNotEmpty) {
        try {
          final barangData = await SupabaseService.table('barang')
              .select('nama_barang, kode_barang')
              .eq('id', barangId)
              .single();
          loanMap['barang'] = barangData;
        } catch (_) {}
      }

      final loan = PeminjamanModel.fromMap(loanMap);

      setState(() {
        _loanDetail = loan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Data peminjaman tidak valid atau tidak ditemukan.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _loanDetail!;
    final fmt = DateFormat('dd MMMM yyyy', 'id');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Aktivitas User'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B3674),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: 'Informasi User',
              items: [
                _buildInfoItem('Nama User', p.namaUser ?? '-'),
                _buildInfoItem('No. WhatsApp', p.noWhatsappUser ?? '-'),
                _buildInfoItem('Departemen', p.departemenUser ?? '-'),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              title: 'Informasi Aset',
              items: [
                _buildInfoItem('Nama Barang', p.namaBarang ?? '-'),
                _buildInfoItem('Kode Barang', p.kodeBarang ?? '-'),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              title: 'Detail Peminjaman',
              items: [
                _buildInfoItem('Status', p.status.toUpperCase()),
                _buildInfoItem('Tanggal Pinjam', fmt.format(p.tanggalPinjam)),
                _buildInfoItem('Rencana Kembali', fmt.format(p.rencanakembali)),
                _buildInfoItem('Alasan', p.alasanMeminjam ?? '-'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2B3674),
                  side: const BorderSide(color: Color(0xFF2B3674)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B3674),
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFA3AED0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2B3674),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
