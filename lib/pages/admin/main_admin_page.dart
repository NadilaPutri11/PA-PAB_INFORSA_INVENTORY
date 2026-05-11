import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../auth/login_page.dart';
import 'dashboard_admin_page.dart';
import 'inventory_admin_page.dart';
import 'approvals_admin_page.dart';
import 'add_item_page.dart';
import 'notification_admin_page.dart';

class MainAdminPage extends StatefulWidget {
  const MainAdminPage({super.key});

  @override
  State<MainAdminPage> createState() => _MainAdminPageState();
}

class _MainAdminPageState extends State<MainAdminPage> {
  int _stackIndex = 0;
  bool _isOpeningAddPage = false;

  final List<Widget> _pages = const [
    DashboardAdminPage(),
    InventoryAdminPage(),
    ApprovalsAdminPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
  }

  void _initNotifications() {
    final notifProvider = context.read<NotificationProvider>();

    notifProvider.fetchAllNotifications();
    notifProvider.subscribeAsAdmin();

    notifProvider.checkAndNotifyOverdue();
  }

  int _navbarToStackIndex(int navbarIndex) {
    switch (navbarIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 3:
        return 2;
      default:
        return 0;
    }
  }

  int _stackToNavbarIndex(int stackIndex) {
    switch (stackIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 3;
      default:
        return 0;
    }
  }

  PageRoute<int> _buildAddItemRoute() {
    return PageRouteBuilder<int>(
      pageBuilder: (_, __, ___) => const AddItemPage(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    context.read<NotificationProvider>().clearNotifications();
    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF1E1E45);
    final user = context.watch<AuthProvider>().currentUser;
    final notifCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyColor,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 46,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10),
          child: Image.asset('assets/logo_inforsa.png', fit: BoxFit.contain),
        ),
        titleSpacing: 4,
        title: const Text(
          'INFORSA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                ),
              ),
              if (notifCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notifCount > 99 ? '99+' : '$notifCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'logout') _handleLogout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nama ?? 'Admin',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Administrator',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Keluar',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      'assets/logo_inforsa.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _stackIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _stackToNavbarIndex(_stackIndex),
        selectedItemColor: navyColor,
        unselectedItemColor: Colors.grey,
        onTap: (navbarIndex) async {
          if (navbarIndex == 2) {
            if (_isOpeningAddPage || !mounted) return;

            _isOpeningAddPage = true;
            try {
              final selectedNavbarIndex = await Navigator.push<int>(
                context,
                _buildAddItemRoute(),
              );

              if (!mounted) return;
              if (selectedNavbarIndex != null && selectedNavbarIndex != 2) {
                setState(() {
                  _stackIndex = _navbarToStackIndex(selectedNavbarIndex);
                });
              }
            } catch (e) {
              debugPrint('Add Item navigation error: $e');
            } finally {
              _isOpeningAddPage = false;
            }
            return;
          }

          setState(() {
            _stackIndex = _navbarToStackIndex(navbarIndex);
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'INVENTORY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 32),
            label: 'ADD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: 'APPROVALS',
          ),
        ],
      ),
    );
  }
}
