import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _isAdmin;
  String? get currentEmail => SupabaseService.auth.currentUser?.email;

  UserModel _applyMetadataFallback(UserModel base, User? user) {
    if (user == null) return base;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final nama = (meta['nama'] ?? meta['full_name'] ?? '').toString().trim();
    final departemen =
        (meta['departemen'] ?? meta['department'] ?? '').toString().trim();
    final nim = (meta['nim'] ?? meta['student_id'] ?? '').toString().trim();
    final noWhatsapp =
        (meta['no_whatsapp'] ?? meta['phone'] ?? '').toString().trim();

    return base.copyWith(
      nama: nama.isNotEmpty ? nama : base.nama,
      departemen: departemen.isNotEmpty ? departemen : base.departemen,
      nim: nim.isNotEmpty ? nim : base.nim,
      noWhatsapp: noWhatsapp.isNotEmpty ? noWhatsapp : base.noWhatsapp,
    );
  }

  bool _isPlaceholderProfile(UserModel? user) {
    if (user == null) return true;

    final nama = user.nama.trim().toLowerCase();
    final departemen = user.departemen.trim();
    final nim = (user.nim ?? '').trim();
    final noWhatsapp = (user.noWhatsapp ?? '').trim();

    final isNamaPlaceholder =
        nama.isEmpty || nama == 'user baru' || nama == 'guest user';
    final isDepartemenPlaceholder =
        departemen.isEmpty || departemen == '-';

    return isNamaPlaceholder ||
        isDepartemenPlaceholder ||
        nim.isEmpty ||
        noWhatsapp.isEmpty;
  }

  Future<bool> _syncProfileFromMetadata(User user) async {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final nama = (meta['nama'] ?? meta['full_name'] ?? '').toString().trim();
    final departemen =
        (meta['departemen'] ?? meta['department'] ?? '').toString().trim();
    final nim = (meta['nim'] ?? meta['student_id'] ?? '').toString().trim();
    final noWhatsapp =
        (meta['no_whatsapp'] ?? meta['phone'] ?? '').toString().trim();

    if (nama.isEmpty && departemen.isEmpty && nim.isEmpty && noWhatsapp.isEmpty) {
      return false;
    }

    final payload = {
      'nama': nama.isEmpty ? 'User Baru' : nama,
      'departemen': departemen.isEmpty ? '-' : departemen,
      'nim': nim.isEmpty ? null : nim,
      'no_whatsapp': noWhatsapp.isEmpty ? null : noWhatsapp,
    };

    // Penting: update dulu agar tidak memicu jalur INSERT (sering kena RLS 42501).
    try {
      await SupabaseService.table('users').update(payload).eq('id', user.id);
      return true;
    } catch (e) {
      print('Sync profile dari metadata gagal (non-blocking): $e');
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Cek role dari user_metadata
        final meta = response.user!.userMetadata;
        _isAdmin = meta?['role'] == 'admin';

        // Fetch profile hanya kalau bukan admin
        // (admin tidak perlu ada di tabel users)
        if (!_isAdmin) {
          await _fetchProfile(response.user!.id);
          if (_isPlaceholderProfile(_currentUser)) {
            final synced = await _syncProfileFromMetadata(response.user!);
            if (synced) {
              await _fetchProfile(response.user!.id);
            }
          }
        } else {
          // Buat UserModel sementara untuk admin
          _currentUser = UserModel(
            id: response.user!.id,
            nama: 'Admin',
            departemen: 'Administrator',
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      print('Auth error: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      print('Error: $e');
      _setError('Terjadi kesalahan. Coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
  required String email,
  required String password,
  required String nama,
  required String nim,          // Tambahkan ini
  required String noWhatsapp,   // Tambahkan ini
  required String departemen,
}) async {
  _setLoading(true);
  try {
    // 1. Mendaftarkan user ke Supabase Auth
    final AuthResponse res = await SupabaseService.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama': nama,
        'departemen': departemen,
        'nim': nim,
        'no_whatsapp': noWhatsapp,
      },
    );

    if (res.user != null) {
      // 2. Memasukkan data tambahan ke tabel 'users' (atau 'profiles')
      // Pastikan nama kolom sesuai dengan yang ada di Supabase Anda
      // Best-effort saja: jika RLS menolak, registrasi tetap dianggap berhasil
      // karena metadata auth sudah tersimpan.
      try {
        await SupabaseService.table('users').update({
          'nama': nama,
          'nim': nim,
          'no_whatsapp': noWhatsapp,
          'departemen': departemen,
        }).eq('id', res.user!.id);
      } catch (e) {
        print('Sinkronisasi tabel users saat register dilewati: $e');
      }
      
      return true;
    }
    return false;
  } catch (e) {
    _errorMessage = e.toString();
    notifyListeners();
    return false;
  } finally {
    _setLoading(false);
  }
}

  Future<void> updatePassword(String newPassword) async {
    await SupabaseService.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final data = await SupabaseService.table(
        'users',
      ).select().eq('id', userId).single();
      var fetchedUser = UserModel.fromMap(data);

      // Jika row DB masih placeholder, tampilkan fallback dari metadata auth
      if (_isPlaceholderProfile(fetchedUser)) {
        fetchedUser = _applyMetadataFallback(
          fetchedUser,
          SupabaseService.auth.currentUser,
        );
      }

      if (_currentUser != null &&
          _currentUser!.id == fetchedUser.id &&
          _isPlaceholderProfile(fetchedUser) &&
          !_isPlaceholderProfile(_currentUser)) {
        return;
      }

      _currentUser = fetchedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      // User belum ada di tabel users (admin langsung dari Supabase)
      _currentUser = null;
    }
  }

  Future<void> refreshProfile() async {
    final user = SupabaseService.auth.currentUser;
    if (user == null) return;

    // Fetch profile terbaru dari database
    await _fetchProfile(user.id);

    // Cek apakah profile placeholder, jika ya sync dari metadata
    if (_isPlaceholderProfile(_currentUser)) {
      final synced = await _syncProfileFromMetadata(user);
      if (synced) {
        await _fetchProfile(user.id);
      }
    }
  }

  Future<bool> updateProfile({
    required String nama,
    required String departemen,
    String? nim,
    String? noWhatsapp,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      print('Updating profile untuk user: ${_currentUser!.id}');
      
      // Update database
      await SupabaseService.table('users')
          .update({
            'nama': nama,
            'departemen': departemen,
            'nim': nim,
            'no_whatsapp': noWhatsapp,
            'avatar_url': avatarUrl,
          })
          .eq('id', _currentUser!.id);

      // Update metadata juga untuk backup sync
      await SupabaseService.auth.updateUser(
        UserAttributes(
          data: {
            'nama': nama,
            'departemen': departemen,
            'nim': nim,
            'no_whatsapp': noWhatsapp,
          },
        ),
      );

      _currentUser = _currentUser!.copyWith(
        nama: nama,
        departemen: departemen,
        nim: nim,
        noWhatsapp: noWhatsapp,
        avatarUrl: avatarUrl,
      );
      notifyListeners();

      await _fetchProfile(_currentUser!.id);
      
      print('Profile fetched successfully');
      
      _setError(null); // Clear any previous errors
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      _setError('Gagal update profil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await SupabaseService.auth.signOut();
    _currentUser = null;
    _isAdmin = false;
    notifyListeners();
  }

  Future<void> checkSession() async {
    final session = SupabaseService.auth.currentSession;
    if (session != null) {
      final meta = session.user.userMetadata;
      _isAdmin = meta?['role'] == 'admin';
      await _fetchProfile(session.user.id);

      if (!_isAdmin && _isPlaceholderProfile(_currentUser)) {
        final synced = await _syncProfileFromMetadata(session.user);
        if (synced) {
          await _fetchProfile(session.user.id);
        }
      }
    }
  }
}
