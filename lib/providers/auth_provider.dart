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
      print('Mencoba login: $email');
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Cek role dari user_metadata
        final meta = response.user!.userMetadata;
        print('User metadata: $meta'); // ← untuk debug
        _isAdmin = meta?['role'] == 'admin';
        print('Is admin: $_isAdmin');

        // Fetch profile hanya kalau bukan admin
        // (admin tidak perlu ada di tabel users)
        if (!_isAdmin) {
          await _fetchProfile(response.user!.id);
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
    final AuthResponse res = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user != null) {
      // 2. Memasukkan data tambahan ke tabel 'users' (atau 'profiles')
      // Pastikan nama kolom sesuai dengan yang ada di Supabase Anda
      await Supabase.instance.client.from('users').insert({
        'id': res.user!.id,
        // 'email': email,
        'nama': nama,
        'nim': nim,                 // Masuk ke kolom nim
        'no_whatsapp': noWhatsapp,  // Masuk ke kolom no_whatsapp
        'departemen': departemen,
        'role': 'user',             // Default role
        'created_at': DateTime.now().toIso8601String(),
      });
      
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
      _currentUser = UserModel.fromMap(data);
      notifyListeners();
    } catch (e) {
      // User belum ada di tabel users (admin langsung dari Supabase)
      _currentUser = null;
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
      await SupabaseService.table('users')
          .update({
            'nama': nama,
            'departemen': departemen,
            'nim': ?nim,
            'no_whatsapp': ?noWhatsapp,
            'avatar_url': ?avatarUrl,
          })
          .eq('id', _currentUser!.id);

      await _fetchProfile(_currentUser!.id);
      return true;
    } catch (e) {
      _setError('Gagal update profil.');
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
    }
  }
}
