import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../../../providers/approval_provider.dart';
import '../../../models/peminjaman_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isDepan) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75, 
    );

    if (photo != null) {
     
      final Uint8List photoBytes = await photo.readAsBytes();

      setState(() {
        if (isDepan) {
          _fotoDepan =
              photoBytes; 
        } else {
          _fotoBelakang =
              photoBytes; 
        }
      });
    }
  }

  // ===== FUNGSI SENSOR LOKASI (GEOFENCING) =====
  Future<bool> _verifyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah GPS HP menyala
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Harap aktifkan GPS / Lokasi HP Anda', isError: true);
      return false;
    }

    // 2. Cek izin aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Izin lokasi ditolak', isError: true);
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'Izin lokasi diblokir permanen di pengaturan HP',
        isError: true,
      );
      return false;
    }

    // 3. Ambil koordinat HP saat ini
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4. Tentukan Koordinat Gudang / Kampus (Titik Pusat)
    double gudangLat = -0.46724599592003246; // Latitude 
    double gudangLng = 117.15718250589005; // Longitude 

    // 5. Hitung jarak HP dengan Gudang (dalam satuan meter)
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      gudangLat,
      gudangLng,
    );

    // 6. Validasi Radius (Contoh: Maksimal 100 meter dari titik)
    if (distanceInMeters > 100) {
      // Getar error karena di luar jangkauan
      Vibration.vibrate(pattern: [0, 150, 100, 150]);
      _showSnackBar(
        'Gagal! Anda berjarak ${distanceInMeters.toStringAsFixed(0)} meter. Harap kembalikan barang langsung di area gudang.',
        isError: true,
      );
      return false;
    }

    return true; 
  }

  Future<void> _handleSubmit() async {
    // Getaran awal
    Vibration.vibrate(duration: 200);

    // Cek foto dulu
    if (_fotoDepan == null || _fotoBelakang == null) {
      Vibration.vibrate(pattern: [0, 150, 100, 150]);
      _showSnackBar('Harap upload foto depan dan belakang', isError: true);
      return;
    }

    // ===== CEK LOKASI SEBELUM UPLOAD =====
    // Tampilkan loading sebentar saat mencari sinyal satelit
    setState(() => _isUploading = true);

    bool isLocationValid = await _verifyLocation();

    if (!isLocationValid) {
      setState(() => _isUploading = false);
      return; 
    }

    try {
      final approval = context.read<ApprovalProvider>();

      // Step 1: Upload foto ke bucket masing-masing
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

      // Step 2: Kirim data ke tabel pengembalian
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
