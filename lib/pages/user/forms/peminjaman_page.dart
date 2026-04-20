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
        _showSnackBar('Permohonan peminjaman berhasil dikirim');
        Navigator.pop(context, true);
      } else {
        throw approval.errorMessage ?? 'Gagal menyimpan data ke database.';
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

    // Gunakan post-frame callback untuk set state agar tidak terjadi rebuild loop
    if (_selectedDepartment == null && user != null) {
      _selectedDepartment = user.departemen;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Form Peminjaman',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF000080).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF000080).withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF000080)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pastikan data diri Anda sudah benar sebelum mengirim permohonan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF000080).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. NAMA PEMINJAM (Auto-fill)
            _buildSectionLabel('NAMA PEMINJAM'),
            _buildReadOnlyField(
              user?.nama ?? 'Nama tidak ditemukan',
              Icons.person_outline,
            ),
            const SizedBox(height: 20),

            // 2. DEPARTEMEN (Auto-fill)
            _buildSectionLabel('DEPARTEMEN'),
            _buildReadOnlyField(
              user?.departemen ?? 'Departemen tidak ditemukan',
              Icons.business_outlined,
            ),
            const SizedBox(height: 20),

            // 3. NAMA BARANG
            _buildSectionLabel('ASET YANG DIPINJAM'),
            _buildReadOnlyField(
              widget.item?.namaBarang ?? '-',
              Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 20),

            // 4. RENCANA PINJAM & KEMBALI
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('TANGGAL PINJAM'),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (d != null) setState(() => _borrowDate = d);
                        },
                        child: _buildDateField(_borrowDate, fmt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('TANGGAL KEMBALI'),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _borrowDate ?? DateTime.now(),
                            firstDate: _borrowDate ?? DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 60)),
                          );
                          if (d != null) setState(() => _returnDate = d);
                        },
                        child: _buildDateField(_returnDate, fmt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Foto Kondisi
            _buildSectionLabel('FOTO KONDISI ASET (WAJIB)'),
            Row(
              children: [
                Expanded(child: _buildPhotoBox('Foto Depan', _foto1, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildPhotoBox('Foto Belakang', _foto2, false)),
              ],
            ),
            const SizedBox(height: 20),

            // 6. ALASAN PEMINJAMAN
            _buildSectionLabel('ALASAN PEMINJAMAN'),
            TextField(
              controller: _alasanController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Contoh: Untuk keperluan dokumentasi event...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Kirim Permohonan Pinjam',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, left: 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    ),
  );

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
