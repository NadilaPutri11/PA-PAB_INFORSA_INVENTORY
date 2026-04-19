import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/approval_provider.dart';

class AdminNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AdminNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final approval = context.watch<ApprovalProvider>();
    final pendingCount =
        approval.pendingPeminjaman.length +
        approval.pendingPerpanjangan.length +
        approval.pendingPengembalian.length;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      selectedItemColor: const Color(0xFF1E1E45),
      unselectedItemColor: Colors.grey,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'DASHBOARD',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'INVENTORY',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 32),
          label: 'ADD',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: pendingCount > 0,
            label: Text(pendingCount.toString()),
            child: const Icon(Icons.fact_check_outlined),
          ),
          label: 'APPROVALS',
        ),
      ],
    );
  }
}
