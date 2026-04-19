import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/approval_provider.dart';
import '../../../models/item_model.dart';
import 'dart:typed_data';

class PeminjamanPage extends StatefulWidget {
  final ItemModel? item;
  const PeminjamanPage({super.key, this.item});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  String? _selectedDepartment;
  DateTime? _borrowDate;
  DateTime? _returnDate;
  Uint8List? _foto1;
  Uint8List? _foto2;
  final _alasanController = TextEditingController();

  @override
  void dispose() {
    _alasanController.dispose(); // Jangan lupa dispose controller
    super.dispose();
  }

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
  }

  // FIX: Sinkronisasi parameter dengan ApprovalProvider
  Future<void> _submit() async {
    if (widget.item == null) return;

    // Validasi: Cek apakah tanggal dan KEDUA foto sudah diisi
    if (_borrowDate == null ||
        _returnDate == null ||
        _foto1 == null ||
        _foto2 == null) {
      _showSnackBar(
        'Mohon lengkapi tanggal dan lampirkan 2 foto kondisi',
        isError: true,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final auth = context.read<AuthProvider>();
      final approval = context.read<ApprovalProvider>();

      // STEP 1: Upload Foto 1
      final String? url1 = await approval.uploadFotoKondisi(
        _foto1!, // Bytes foto harus di urutan pertama
        'jpg',
        'pjm_front_${DateTime.now().millisecondsSinceEpoch}', // Nama file di urutan ketiga
      );

      // STEP 2: Upload Foto 2
      final String? url2 = await approval.uploadFotoKondisi(
        _foto2!,
        'jpg',
        'pjm_back_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (url1 == null || url2 == null) throw 'Gagal mengunggah foto kondisi.';

      // STEP 3: Gabungkan dua URL menjadi satu string dengan pemisah koma
      final String combinedUrls = "$url1,$url2";

      final success = await approval.submitPeminjaman(
        userId: auth.currentUser!.id,
        barangId: widget.item!.id,
        tanggalPinjam: _borrowDate!,
        rencanaKembali: _returnDate!,
        alasan: _alasanController.text.trim(),
        fotoUrl: combinedUrls, // Kirim string gabungan
      );

      if (success && mounted) {
        _showSnackBar('Permintaan berhasil dikirim');
        Navigator.pop(context, true);
      } else {
        throw 'Gagal menyimpan data ke database.';
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    // Ambil data user dari AuthProvider
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    // Set nilai departemen otomatis untuk kebutuhan submit
    if (_selectedDepartment == null && user != null) {
      _selectedDepartment = user.departemen;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Form Peminjaman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. NAMA PEMINJAM (Otomatis dari Register)
            const Text(
              'Nama Peminjam',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              user?.nama ?? 'Nama tidak ditemukan',
              Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // 2. DEPARTEMEN (Otomatis dari Register)
            const Text(
              'Departemen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              user?.departemen ?? 'Departemen tidak ditemukan',
              Icons.business_outlined,
            ),
            const SizedBox(height: 16),

            // 3. NAMA BARANG
            const Text(
              'Nama Barang',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              widget.item?.namaBarang ?? '-',
              Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 16),

            // 4. RENCANA PINJAM
            const Text(
              'Rencana Pinjam',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _borrowDate = d);
              },
              child: _buildDateField(_borrowDate, fmt),
            ),
            const SizedBox(height: 16),

            // 5. RENCANA KEMBALI
            const Text(
              'Rencana Kembali',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _borrowDate ?? DateTime.now(),
                  firstDate: _borrowDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (d != null) setState(() => _returnDate = d);
              },
              child: _buildDateField(_returnDate, fmt),
            ),
            const SizedBox(height: 16),

            // Di dalam Column children:
            const Text(
              'Foto Kondisi Aset (Depan & Belakang)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPhotoBox('Foto Depan', _foto1, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildPhotoBox('Foto Belakang', _foto2, false)),
              ],
            ),
            const SizedBox(height: 16),

            // 6. ALASAN PEMINJAMAN
            const Text(
              'Alasan Peminjaman',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan...',
                filled: true,
                fillColor: const Color(0xFFEBECEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF000080,
                  ), // Warna Navy sesuai desain
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Permintaan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String text, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEBECEF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _buildDateField(DateTime? date, DateFormat fmt) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEBECEF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: Colors.black54,
        ),
        const SizedBox(width: 12),
        Text(date == null ? 'Pilih Tanggal' : fmt.format(date)),
      ],
    ),
  );

  Widget _buildPhotoBox(String label, Uint8List? bytes, bool isFirst) {
    return GestureDetector(
      onTap: () => _pickImage(isFirst),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFEBECEF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: bytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage(bool isDepan) async {
    // Gunakan sintaks yang sama dengan pengembalian_page.dart
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (isDepan) {
          _foto1 = result.files.single.bytes;
        } else {
          _foto2 = result.files.single.bytes;
        }
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
