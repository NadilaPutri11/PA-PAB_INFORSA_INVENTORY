import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../pages/user/notification_page.dart';
import '../pages/user/profile_page.dart';

class InforsaHeader extends StatelessWidget implements PreferredSizeWidget {
  const InforsaHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final unreadCount = notifProvider.notifications.where((n) => !n.isRead).length;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 46,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Image.asset(
          'assets/logo_inforsa.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.shield_outlined,
            color: Color(0xFF1A1F35),
            size: 18,
          ),
        ),
      ),
      titleSpacing: 4,
      title: const Text(
        'INFORSA',
        style: TextStyle(
          color: Color(0xFF1A1F35),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 20,
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1F35)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationPage()),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20, left: 8),
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}
