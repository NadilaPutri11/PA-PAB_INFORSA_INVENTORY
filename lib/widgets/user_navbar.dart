import 'package:flutter/material.dart';

class UserNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const UserNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Icon(Icons.grid_view_rounded),
            ),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Icon(Icons.layers_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Icon(Icons.layers),
            ),
            label: 'INVENTORY',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Icon(Icons.history),
            ),
            label: 'ACTIVITY',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Icon(Icons.person_outline),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Icon(Icons.person),
            ),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
