import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/inforsa_header.dart';
import '../../widgets/user_navbar.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Refresh data user saat profile page dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.refreshProfile();
    });
  }

  bool _isPlaceholderProfile(dynamic user) {
    if (user == null) return true;
    final nama = (user.nama ?? '').trim().toLowerCase();
    final departemen = (user.departemen ?? '').trim();
    final nim = (user.nim ?? '').trim();
    final noWhatsapp = (user.noWhatsapp ?? '').trim();

    final isNamaPlaceholder =
        nama.isEmpty || nama == 'user baru' || nama == 'guest user';
    final isDepartemenPlaceholder = departemen.isEmpty || departemen == '-';

    return isNamaPlaceholder ||
        isDepartemenPlaceholder ||
        nim.isEmpty ||
        noWhatsapp.isEmpty;
  }

  String _initialsFromName(String? fullName) {
    final source = (fullName ?? '').trim();
    if (source.isEmpty) return 'U';

    final parts = source
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // FUNGSI BARU: Langsung membuka link WA spesifik yang Anda minta [Terupdate]
  Future<void> _openWhatsAppLink() async {
    final Uri url = Uri.parse("https://wa.me/6281350918562");

    try {
      // Menggunakan LaunchMode.externalApplication agar langsung membuka aplikasi WA
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Gagal membuka link WhatsApp');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // Fungsi Modal Informasi Lainnya tetap dipertahankan
  void _showInformasiLainnya(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Informasi Lainnya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoLainItem(
              Icons.email_outlined,
              'inforsabiroindustrikreatif@gmail.com',
            ),
            const SizedBox(height: 16),
            _buildInfoLainItem(
              Icons.access_time_rounded,
              'Senin - Jumat, 08.00 - 17.00 WITA',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF000080),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLainItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF000080), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    
    // Cek apakah halaman ini di-push standalone atau bagian dari MainUserPage
    final isStandalone = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const InforsaHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      _initialsFromName(user?.nama),
                      style: const TextStyle(
                        color: Color(0xFF000080),
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.nama ?? 'Guest User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.departemen ?? 'Unit Tidak Diketahui',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        authProvider.refreshProfile();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data profil diperbarui'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Sinkronisasi Data'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF000080)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "BIODATA DIRI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F35),
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () => _showEditProfileDialog(context, auth),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF000080),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileInfo(user, auth.currentEmail),

            const SizedBox(height: 12),

            const Text(
              "Keamanan",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: Color(0xFF000080)),
              title: const Text(
                "Ubah Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showUbahPasswordDialog(context),
            ),

            const SizedBox(height: 24),

            const Text(
              "Pusat Bantuan",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Tombol Chat Admin (Link WA Tersemat)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () =>
                    _openWhatsAppLink(), // Memanggil link https://wa.me/6281350918562
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF000080)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Chat Admin INFORSA",
                  style: TextStyle(
                    color: Color(0xFF000080),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Informasi Lainnya
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => _showInformasiLainnya(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Informasi Lainnya",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEBEB),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Keluar Akun",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: isStandalone ? const UserNavbar(selectedIndex: 3, onItemTapped: _naviateToPage) : null,
    );
  }

  static void _naviateToPage(int index) {
    // Ini callback untuk navbar standalone
  }

  // --- BAGIAN DIALOG (TETAP SAMA) ---

  Widget _buildProfileInfo(dynamic user, String? email) {
    return Column(
      children: [
        _buildInfoItem('NAMA LENGKAP', user?.nama ?? '-', Icons.person_outline),
        _buildInfoItem('NIM / ID', user?.nim ?? '-', Icons.badge_outlined),
        _buildInfoItem(
          'DEPARTEMEN',
          user?.departemen ?? '-',
          Icons.business_outlined,
        ),
        _buildInfoItem(
          'NOMOR WHATSAPP',
          user?.noWhatsapp ?? '-',
          Icons.phone_android_outlined,
        ),
        _buildInfoItem('EMAIL', email ?? '-', Icons.email_outlined),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF000080).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF000080), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    
    // Coba ambil data dari metadata jika available
    final currentUser = auth.currentUser;
    final namaController = TextEditingController(
      text: currentUser?.nama ?? 'User Baru',
    );
    final nimController = TextEditingController(text: currentUser?.nim ?? '');
    final waController =
        TextEditingController(text: currentUser?.noWhatsapp ?? '');
    
    final List<String> departments = [
      'PSD',
      'RELACS',
      'BUREAU EDEN',
      'HRD',
      'ADWEL',
    ];
    String selectedDept = departments.contains(user?.departemen)
        ? user!.departemen
        : departments.first;

    final isAutoEdit = _isPlaceholderProfile(user);

    showDialog(
      context: context,
      barrierDismissible: !isAutoEdit, // Prevent dismiss jika auto-edit
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isSaving = false;

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAutoEdit ? 'Lengkapi Data Profil Anda' : 'Edit Profil',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAutoEdit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Silakan lengkapi data profil Anda untuk melanjutkan',
                                style: TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  TextField(
                    controller: namaController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap Anda',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nimController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'NIM / ID',
                      hintText: 'Masukkan NIM atau ID Anda',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedDept,
                    isExpanded: true,
                    disabledHint: Text(selectedDept),
                    items: isSaving
                        ? null
                        : departments
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                    onChanged: isSaving
                        ? null
                        : (val) => setStateDialog(() => selectedDept = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: waController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'No. WhatsApp',
                      hintText: 'Contoh: 6281234567890',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              if (!isAutoEdit && !isSaving)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final nama = namaController.text.trim();
                        final nim = nimController.text.trim();
                        final wa = waController.text.trim();

                        if (nama.isEmpty || nim.isEmpty || wa.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua field harus diisi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        setStateDialog(() => isSaving = true);

                        final success = await auth.updateProfile(
                          nama: nama,
                          departemen: selectedDept,
                          nim: nim,
                          noWhatsapp: wa,
                        );

                        if (!context.mounted) return;

                        setStateDialog(() => isSaving = false);

                        if (success) {
                          Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil berhasil diperbarui!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menyimpan profil. Silakan coba lagi.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isAutoEdit ? 'Simpan & Lanjutkan' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUbahPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password Lama'),
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}
