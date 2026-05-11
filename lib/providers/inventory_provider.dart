import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_model.dart';
import '../services/supabase_service.dart';

class InventoryProvider extends ChangeNotifier {
  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  Future<void>? _ongoingFetch;
  DateTime? _lastFetchedAt;

  static const Duration _cacheTtl = Duration(seconds: 15);

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchItems({bool forceRefresh = false, bool showLoading = true}) {
    if (_ongoingFetch != null) {
      return _ongoingFetch!;
    }

    final hasFreshCache =
        !forceRefresh &&
        _items.isNotEmpty &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < _cacheTtl;

    if (hasFreshCache) {
      return Future.value();
    }

    final shouldShowLoading = showLoading && _items.isEmpty;

    _ongoingFetch = () async {
      if (shouldShowLoading) {
        _setLoading(true);
      }

      _setError(null);

      try {
        final data = await SupabaseService.table(
          'barang',
        ).select().order('created_at', ascending: false);
        _items = (data as List).map((e) => ItemModel.fromMap(e)).toList();
        _lastFetchedAt = DateTime.now();

        if (!shouldShowLoading) {
          notifyListeners();
        }
      } catch (e) {
        _setError('Gagal memuat data barang.');
      } finally {
        if (shouldShowLoading) {
          _setLoading(false);
        }
        _ongoingFetch = null;
      }
    }();

    return _ongoingFetch!;
  }

  Future<bool> addItem(ItemModel item) async {
    _setLoading(true);
    _setError(null);
    try {
      await SupabaseService.table('barang').insert(item.toMap());
      await fetchItems();
      return true;
    } on PostgrestException catch (e) {
      final detailsText = e.details?.toString();
      final parts = <String>[
        if (e.code != null && e.code!.isNotEmpty) 'code: ${e.code}',
        if (e.message.isNotEmpty) e.message,
        if (detailsText != null && detailsText.isNotEmpty)
          'details: $detailsText',
      ];
      final message = parts.join(' | ');
      debugPrint('addItem PostgrestException: $message');
      _setError('Gagal menambah barang: $message');
      return false;
    } catch (e) {
      debugPrint('addItem error: $e');
      _setError('Gagal menambah barang: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateItem(ItemModel item) async {
    _setLoading(true);
    _setError(null);
    try {
      await SupabaseService.table(
        'barang',
      ).update(item.toMap()).eq('id', item.id);
      await fetchItems();
      return true;
    } catch (e) {
      _setError('Gagal mengupdate barang.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteItem(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      final itemData = await SupabaseService.table('barang').select().eq('id', id).single();
      final item = ItemModel.fromMap(itemData);
      final peminjamanList = await SupabaseService.table('peminjaman')
          .select('id')
          .eq('barang_id', id);
      
      final peminjamanIds = (peminjamanList as List)
          .map((p) => p['id'] as String)
          .toList();

      debugPrint('Found ${peminjamanIds.length} peminjaman records for barang_id: $id');

      if (peminjamanIds.isNotEmpty) {
        for (final peminjamanId in peminjamanIds) {
          await SupabaseService.table('pengembalian')
              .delete()
              .eq('peminjaman_id', peminjamanId);
        }
        debugPrint('Deleted pengembalian records for peminjaman_ids: $peminjamanIds');

        for (final peminjamanId in peminjamanIds) {
          await SupabaseService.table('perpanjangan')
              .delete()
              .eq('peminjaman_id', peminjamanId);
        }
        debugPrint('Deleted perpanjangan records for peminjaman_ids: $peminjamanIds');
      }

      await SupabaseService.table('peminjaman')
          .delete()
          .eq('barang_id', id);
      debugPrint('Deleted peminjaman records for barang_id: $id');

      if (item.fotoUrl != null) {
        final path = _extractPathFromUrl(item.fotoUrl!);
        if (path != null) {
          await SupabaseService.storage.from('foto_barang').remove([path]);
        }
      }
      if (item.dokumenNotaUrl != null) {
        final path = _extractPathFromUrl(item.dokumenNotaUrl!);
        if (path != null) {
          await SupabaseService.storage.from('dokumen_nota').remove([path]);
        }
      }

      await SupabaseService.table('barang').delete().eq('id', id);
      await fetchItems();
      return true;
    } catch (e) {
      debugPrint('deleteItem error: $e');
      _setError('Gagal menghapus barang.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('public') + 2; 
      if (bucketIndex < segments.length) {
        return segments.sublist(bucketIndex).join('/');
      }
    } catch (_) {}
    return null;
  }

  Future<String?> uploadFotoBarang(
    String itemCode,
    Uint8List bytes,
    String extension,
  ) async {
    try {
      const maxSizeMB = 10;
      if (bytes.lengthInBytes > maxSizeMB * 1024 * 1024) {
        final errorMsg = 'File terlalu besar. Maksimal $maxSizeMB MB.';
        _setError(errorMsg);
        debugPrint('uploadFotoBarang: $errorMsg');
        return null;
      }

      debugPrint('uploadFotoBarang: Starting upload (${bytes.lengthInBytes} bytes)');

      final fileName = '${itemCode}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'barang/$fileName';
      
      debugPrint('uploadFotoBarang: Uploading to path: $path');
      
      await SupabaseService.storage
          .from('foto_barang')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}',
              upsert: true,
            ),
          );
      
      debugPrint('uploadFotoBarang: Upload successful, getting public URL');
      final publicUrl = SupabaseService.storage.from('foto_barang').getPublicUrl(path);
      debugPrint('uploadFotoBarang: Public URL: $publicUrl');
      
      return publicUrl;
    } on StorageException catch (e) {
      final errorMsg = 'Upload error: ${e.statusCode} - ${e.message}';
      _setError(errorMsg);
      debugPrint('uploadFotoBarang StorageException: $errorMsg');
      return null;
    } catch (e) {
      final errorMsg = 'Gagal upload foto barang: $e';
      _setError(errorMsg);
      debugPrint('uploadFotoBarang error: $errorMsg');
      return null;
    }
  }

  Future<String?> uploadDokumenNota(
    String itemCode,
    Uint8List bytes,
    String extension,
  ) async {
    try {
      const maxSizeMB = 20;
      if (bytes.lengthInBytes > maxSizeMB * 1024 * 1024) {
        final errorMsg = 'File terlalu besar. Maksimal $maxSizeMB MB.';
        _setError(errorMsg);
        debugPrint('uploadDokumenNota: $errorMsg');
        return null;
      }

      debugPrint('uploadDokumenNota: Starting upload (${bytes.lengthInBytes} bytes)');
      
      final fileName = '${itemCode}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'nota/$fileName';
      
      debugPrint('uploadDokumenNota: Uploading to path: $path');
      
      await SupabaseService.storage
          .from('dokumen_nota')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: extension == 'pdf'
                  ? 'application/pdf'
                  : 'image/${extension == 'jpg' ? 'jpeg' : extension}',
              upsert: true,
            ),
          );
      
      debugPrint('uploadDokumenNota: Upload successful, getting public URL');
      final publicUrl = SupabaseService.storage.from('dokumen_nota').getPublicUrl(path);
      debugPrint('uploadDokumenNota: Public URL: $publicUrl');
      
      return publicUrl;
    } on StorageException catch (e) {
      final errorMsg = 'Upload error: ${e.statusCode} - ${e.message}';
      _setError(errorMsg);
      debugPrint('uploadDokumenNota StorageException: $errorMsg');
      return null;
    } catch (e) {
      final errorMsg = 'Gagal upload dokumen: $e';
      _setError(errorMsg);
      debugPrint('uploadDokumenNota error: $errorMsg');
      return null;
    }
  }
}

