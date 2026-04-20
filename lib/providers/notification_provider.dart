import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  RealtimeChannel? _channel;
  String? _subscribedUserId;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ── Fetch untuk User (filter by userId) ────────────────────────────────────
  Future<void> fetchNotifications(String userId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table(
        'notifications',
      ).select().eq('user_id', userId).order('created_at', ascending: false);
      _notifications = (data as List)
          .map((e) => NotificationModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetch notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Fetch untuk Admin (semua notifikasi) ────────────────────────────────────
  Future<void> fetchAllNotifications() async {
    _setLoading(true);
    try {
      final data = await SupabaseService.table(
        'notifications',
      ).select().order('created_at', ascending: false);
      _notifications = (data as List)
          .map((e) => NotificationModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetch all notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Realtime untuk User (filter by userId) ──────────────────────────────────
  void subscribeToNotifications(String userId) {
    if (_subscribedUserId == userId && _channel != null) return;
    unsubscribe();
    _subscribedUserId = userId;

    _channel = SupabaseService.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final newNotif = NotificationModel.fromMap(payload.newRecord);
              _notifications.insert(0, newNotif);
              notifyListeners();
              debugPrint('Realtime user: notif baru → ${newNotif.title}');
            } catch (e) {
              debugPrint('Realtime parse error: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('Realtime user status: $status');
          if (error != null) debugPrint('Realtime user error: $error');
        });
  }

  // ── Realtime untuk Admin (semua notifikasi tanpa filter) ────────────────────
  void subscribeAsAdmin() {
    if (_subscribedUserId == 'admin' && _channel != null) return;
    unsubscribe();
    _subscribedUserId = 'admin';

    _channel = SupabaseService.client
        .channel('notifications:admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          // Tidak ada filter → listen semua INSERT di tabel notifications
          callback: (payload) {
            try {
              final newNotif = NotificationModel.fromMap(payload.newRecord);
              _notifications.insert(0, newNotif);
              notifyListeners();
              debugPrint('Realtime admin: notif baru → ${newNotif.title}');
            } catch (e) {
              debugPrint('Realtime parse error: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('Realtime admin status: $status');
          if (error != null) debugPrint('Realtime admin error: $error');
        });
  }

  // ── Unsubscribe ─────────────────────────────────────────────────────────────
  void unsubscribe() {
    if (_channel != null) {
      SupabaseService.client.removeChannel(_channel!);
      _channel = null;
      _subscribedUserId = null;
      debugPrint('Realtime: unsubscribed');
    }
  }

  // ── Mark as Read ────────────────────────────────────────────────────────────
  Future<void> markAsRead(String notifId) async {
    try {
      await SupabaseService.table(
        'notifications',
      ).update({'is_read': true}).eq('id', notifId);
      final index = _notifications.indexWhere((n) => n.id == notifId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error mark as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await SupabaseService.table(
        'notifications',
      ).update({'is_read': true}).eq('user_id', userId);
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error mark all as read: $e');
    }
  }

  // Khusus admin — tandai semua dibaca tanpa filter userId
  Future<void> markAllAsReadAdmin() async {
    try {
      // Update semua notif yang belum dibaca
      final unreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();
      if (unreadIds.isEmpty) return;

      await SupabaseService.table(
        'notifications',
      ).update({'is_read': true}).inFilter('id', unreadIds);
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error mark all as read admin: $e');
    }
  }

  // ── Auto-Notification for Overdue (Admin) ──────────────────────────────────
  Future<void> checkAndNotifyOverdue() async {
    try {
      final now = DateTime.now();
      final loansRes = await SupabaseService.table('peminjaman')
          .select('*, users(nama), barang(nama_barang)')
          .eq('status', 'disetujui')
          .lt('rencana_kembali', now.toIso8601String());

      for (var loan in (loansRes as List)) {
        final userName = loan['users']['nama'];
        final assetName = loan['barang']['nama_barang'];

        // Cek apakah sudah ada notif jatuh tempo untuk peminjaman ini hari ini
        final today = DateTime(now.year, now.month, now.day);
        final existingNotif = await SupabaseService.table('notifications')
            .select()
            .eq('title', 'Jatuh Tempo!')
          .ilike('message', '%$assetName%')
            .gte('created_at', today.toIso8601String());

        if ((existingNotif as List).isEmpty) {
          await SupabaseService.table('notifications').insert({
            'user_id': null,
            'title': 'Jatuh Tempo!',
            'message':
                'Peminjaman $assetName oleh $userName telah melewati batas waktu.',
            'type': 'peminjaman',
            'is_read': false,
          });
          debugPrint('Notification created for overdue asset: $assetName');
        }
      }
    } catch (e) {
      debugPrint('Error checkAndNotifyOverdue: $e');
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────
  void clearNotifications() {
    _notifications = [];
    unsubscribe();
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
