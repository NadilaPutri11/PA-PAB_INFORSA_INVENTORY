import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchAllNotifications();
    });
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    return '${diff.inDays} hari yang lalu';
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'peminjaman':
        return Icons.assignment_outlined;
      case 'perpanjangan':
        return Icons.history;
      case 'pengembalian':
        return Icons.check_box_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'peminjaman':
        return const Color(0xFF1E40AF);
      case 'perpanjangan':
        return const Color(0xFFB45309);
      case 'pengembalian':
        return const Color(0xFF15803D);
      default:
        return const Color(0xFF1E40AF);
    }
  }

  Color _getIconBgColor(String? type) {
    switch (type) {
      case 'peminjaman':
        return const Color(0xFFDBEAFE);
      case 'perpanjangan':
        return const Color(0xFFFEF3C7);
      case 'pengembalian':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF1E1E45);
    final notifProvider = context.watch<NotificationProvider>();

    final now = DateTime.now();
    final hariIni = notifProvider.notifications.where((n) {
      if (n.createdAt == null) return false;
      return n.createdAt!.day == now.day &&
          n.createdAt!.month == now.month &&
          n.createdAt!.year == now.year;
    }).toList();

    final sebelumnya = notifProvider.notifications.where((n) {
      if (n.createdAt == null) return true;
      return !(n.createdAt!.day == now.day &&
          n.createdAt!.month == now.month &&
          n.createdAt!.year == now.year);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: navyColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<NotificationProvider>().fetchAllNotifications(),
              child: notifProvider.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TERBARU',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (notifProvider.unreadCount > 0)
                                  GestureDetector(
                                    onTap: () =>
                                        notifProvider.markAllAsReadAdmin(),
                                    child: const Text(
                                      'Tandai semua dibaca',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          if (hariIni.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _buildDateDivider('HARI INI'),
                            ),
                            const SizedBox(height: 16),
                            ...hariIni.map(
                              (n) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _buildNotifCard(
                                  context,
                                  n,
                                  notifProvider,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (sebelumnya.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _buildDateDivider('SEBELUMNYA'),
                            ),
                            const SizedBox(height: 16),
                            ...sebelumnya.map(
                              (n) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _buildNotifCard(
                                  context,
                                  n,
                                  notifProvider,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              'Menampilkan ${notifProvider.notifications.length} notifikasi',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildDateDivider(String text) {
    return Row(
      children: [
        Text(
          text,
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

  Widget _buildNotifCard(
    BuildContext context,
    NotificationModel n,
    NotificationProvider provider,
  ) {
    return GestureDetector(
      onTap: () {
        if (!n.isRead) provider.markAsRead(n.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: !n.isRead
              ? const Border(
                  left: BorderSide(color: Color(0xFF1E3A8A), width: 4),
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconBgColor(n.type),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIcon(n.type),
                color: _getIconColor(n.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: n.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: '  ${n.message}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeAgo(n.createdAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      if (!n.isRead) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E40AF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
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
