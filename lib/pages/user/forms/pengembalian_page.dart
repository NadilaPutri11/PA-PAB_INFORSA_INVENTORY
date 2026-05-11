import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../../../providers/approval_provider.dart';
import '../../../models/peminjaman_model.dart';

class PengembalianPage extends StatefulWidget {
  final PeminjamanModel peminjaman;

  const PengembalianPage({super.key, required this.peminjaman});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  final _catatanController = TextEditingController();
  Uint8List? _fotoDepan;
  Uint8List? _fotoBelakang;
  bool _isUploading = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isDepan) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (isDepan) {
          _fotoDepan = result.files.single.bytes;
        } else {
          _fotoBelakang = result.files.single.bytes;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_fotoDepan == null || _fotoBelakang == null) {
      _showSnackBar('Harap upload foto depan dan belakang', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final approval = context.read<ApprovalProvider>();

      String? urlDepan;
      String? urlBelakang;

      try {
        urlDepan = await approval.uploadFotoKondisi(
          _fotoDepan!,
          'jpg',
          'foto-pengembalian-depan',
        );
        urlBelakang = await approval.uploadFotoKondisi(
          _fotoBelakang!,
          'jpg',
          'foto-pengembalian-belakang',
        );
      } catch (e) {
        throw 'Gagal upload foto: $e';
      }

      final success = await approval.submitPengembalian(
        peminjamanId: widget.peminjaman.id,
        fotoDepanUrl: urlDepan!,
        fotoBelakangUrl: urlBelakang!,
        catatan: _catatanController.text.trim(),
      );

      if (success && mounted) {
        _showSnackBar('Pengembalian berhasil diajukan!');
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
    final p = widget.peminjaman;
    final fmt = DateFormat('dd MMM yyyy', 'id');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context), // Tombol Kembali
        ),
        title: const Text(
          'Pengembalian Aset',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: Center(
              child: Text(
                'INFORSA',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Detail
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NAMA ASSET',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            p.namaBarang ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateInfo(
                        'TANGGAL PINJAM',
                        fmt.format(p.tanggalPinjam),
                      ),
                      _buildDateInfo(
                        'JATUH TEMPO',
                        fmt.format(p.rencanakembali),
                        isRed: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Kondisi Asset Setelah Pemakaian',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPhotoBox('Foto Depan', _fotoDepan, true)),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoBox('Foto Belakang', _fotoBelakang, false),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Catatan Tambahan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _catatanController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tuliskan jika ada kerusakan...',
                filled: true,
                fillColor: const Color(0xFFEBECEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Konfirmasi Pengembalian',
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

  Widget _buildDateInfo(String label, String date, {bool isRed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          date,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isRed ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoBox(String label, Uint8List? bytes, bool isDepan) {
    return GestureDetector(
      onTap: () => _pickImage(isDepan),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFEBECEF),
          borderRadius: BorderRadius.circular(12),
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
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
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
