import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/item_model.dart';
import '../services/supabase_service.dart';

class InventoryProvider extends ChangeNotifier {
  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> fetchItems() async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await SupabaseService.table(
        'barang',
      ).select().order('created_at', ascending: false);
      _items = (data as List).map((e) => ItemModel.fromMap(e)).toList();
    } catch (e) {
      _setError('Gagal memuat data barang.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addItem(ItemModel item) async {
    _setLoading(true);
    _setError(null);
    try {
      await SupabaseService.table('barang').insert(item.toMap());
      await fetchItems();
      return true;
    } catch (e) {
      _setError('Gagal menambah barang.');
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
      // 1. Get item data to find file paths
      final itemData = await SupabaseService.table('barang').select().eq('id', id).single();
      final item = ItemModel.fromMap(itemData);

      // 2. Delete files from storage if they exist
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

      // 3. Delete from database
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

  // Helper to extract relative path from Supabase Public URL
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Index of bucket name + 1
      final bucketIndex = segments.indexOf('public') + 2; 
      if (bucketIndex < segments.length) {
        return segments.sublist(bucketIndex).join('/');
      }
    } catch (_) {}
    return null;
  }

  // Upload foto barang ke Supabase Storage
  Future<String?> uploadFotoBarang(
    String itemCode,
    Uint8List bytes,
    String extension,
  ) async {
    try {
      // Menambahkan timestamp agar unik dan menghindari caching browser
      final fileName = '${itemCode}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'barang/$fileName';
      
      await SupabaseService.storage
          .from('foto_barang')
          .uploadBinary(path, bytes);
      return SupabaseService.storage.from('foto_barang').getPublicUrl(path);
    } catch (e) {
      _setError('Gagal upload foto barang.');
      debugPrint('uploadFotoBarang error: $e');
      return null;
    }
  }

  // Upload dokumen nota ke Supabase Storage
  Future<String?> uploadDokumenNota(
    String itemCode,
    Uint8List bytes,
    String extension,
  ) async {
    try {
      final fileName = '${itemCode}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'nota/$fileName';
      
      await SupabaseService.storage
          .from('dokumen_nota')
          .uploadBinary(path, bytes);
      return SupabaseService.storage.from('dokumen_nota').getPublicUrl(path);
    } catch (e) {
      _setError('Gagal upload dokumen.');
      return null;
    }
  }
}

