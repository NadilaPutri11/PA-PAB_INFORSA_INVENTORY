import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      final notifProvider = context.read<NotificationProvider>();
      await notifProvider.fetchNotifications(userId);
      notifProvider.subscribeToNotifications(userId);
    }
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<NotificationProvider>().fetchNotifications(userId);
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari yang lalu';
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'peminjaman':
        return Icons.assignment_outlined;
      case 'perpanjangan':
        return Icons.history_outlined;
      case 'pengembalian':
        return Icons.assignment_return_outlined;
      case 'overdue':
        return Icons.warning_amber_rounded;
      case 'reminder':
        return Icons.access_time_rounded;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'overdue':
        return const Color(0xFFDC2626);
      case 'reminder':
        return const Color(0xFFD97706);
      case 'pengembalian':
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF1E40AF);
    }
  }

  Color _getIconBgColor(String? type) {
    switch (type) {
      case 'overdue':
        return const Color(0xFFFEE2E2);
      case 'reminder':
        return const Color(0xFFFEF3C7);
      case 'pengembalian':
      case 'approved':
        return const Color(0xFFDCFCE7);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id;

    final now = DateTime.now();

    final hariIni = notifProvider.notifications.where((n) {
      if (n.createdAt == null) return false;
      return n.createdAt!.day == now.day &&
          n.createdAt!.month == now.month &&
          n.createdAt!.year == now.year;
    }).toList();

    final kemarin = notifProvider.notifications.where((n) {
      if (n.createdAt == null) return false;
      final yesterday = now.subtract(const Duration(days: 1));
      return n.createdAt!.day == yesterday.day &&
          n.createdAt!.month == yesterday.month &&
          n.createdAt!.year == yesterday.year;
    }).toList();

    final lebihLama = notifProvider.notifications.where((n) {
      if (n.createdAt == null) return true;
      final yesterday = now.subtract(const Duration(days: 1));
      final isHariIni =
          n.createdAt!.day == now.day &&
          n.createdAt!.month == now.month &&
          n.createdAt!.year == now.year;
      final isKemarin =
          n.createdAt!.day == yesterday.day &&
          n.createdAt!.month == yesterday.month &&
          n.createdAt!.year == yesterday.year;
      return !isHariIni && !isKemarin;
    }).toList();

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
          'INFORSA',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (notifProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifikasi',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Kelola pembaruan dan status inventaris Anda.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (notifProvider.unreadCount > 0)
                          GestureDetector(
                            onTap: () {
                              if (userId != null) {
                                notifProvider.markAllAsRead(userId);
                              }
                            },
                            child: const Text(
                              'Tandai\ndibaca',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                                height: 1.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Empty state
                    if (notifProvider.notifications.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada notifikasi',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (hariIni.isNotEmpty) ...[
                      _buildSectionLabel('HARI INI'),
                      const SizedBox(height: 12),
                      ...hariIni.map((n) => _buildNotifCard(n, notifProvider)),
                      const SizedBox(height: 24),
                    ],

                    if (kemarin.isNotEmpty) ...[
                      _buildSectionLabel('KEMARIN'),
                      const SizedBox(height: 12),
                      ...kemarin.map((n) => _buildNotifCard(n, notifProvider)),
                      const SizedBox(height: 24),
                    ],

                    if (lebihLama.isNotEmpty) ...[
                      _buildSectionLabel('SEBELUMNYA'),
                      const SizedBox(height: 12),
                      ...lebihLama.map(
                        (n) => _buildNotifCard(n, notifProvider),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildNotifCard(NotificationModel n, NotificationProvider provider) {
    return GestureDetector(
      onTap: () {
        if (!n.isRead) provider.markAsRead(n.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconBgColor(n.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(n.type),
                color: _getIconColor(n.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Konten
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Text(
                            _timeAgo(n.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (!n.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getIconColor(n.type),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
