import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civil_management/features/profile/screens/profile_screen.dart';
import 'package:civil_management/features/projects/screens/project_list_screen.dart';
import 'package:civil_management/features/bills/screens/bills_screen.dart';
import 'package:civil_management/features/reports/screens/reports_screen.dart';
import 'package:civil_management/features/dashboard/screens/admin_dashboard.dart';
import 'package:civil_management/core/theme/app_colors.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const ProjectListScreen(),
    const BillsScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(context, _selectedIndex),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _buildNavItem(
                icon: Icons.business,
                label: 'Projects',
                isSelected: currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _buildNavItem(
                icon: Icons.receipt_long,
                label: 'Bills',
                isSelected: currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              _buildNavItem(
                icon: Icons.bar_chart,
                label: 'Reports',
                isSelected: currentIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => _onItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
