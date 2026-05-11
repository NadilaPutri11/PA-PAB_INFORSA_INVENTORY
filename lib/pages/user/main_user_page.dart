import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'dashboard_user_page.dart';
import 'inventory_user_page.dart';
import 'activity_page.dart';
import 'profile_page.dart';
import '../../widgets/user_navbar.dart';

class MainUserPage extends StatefulWidget {
  const MainUserPage({super.key});

  @override
  State<MainUserPage> createState() => _MainUserPageState();
}

class _MainUserPageState extends State<MainUserPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardUserPage(),
    const InventoryUserPage(),
    const ActivityPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
  }

  void _initNotifications() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final notifProvider = context.read<NotificationProvider>();

    notifProvider.fetchNotifications(userId);

    notifProvider.subscribeToNotifications(userId);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: UserNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
