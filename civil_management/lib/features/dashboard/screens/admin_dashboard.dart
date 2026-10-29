import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/projects/providers/project_provider.dart';
import '../../../features/projects/data/models/project_model.dart';

/// Admin Dashboard matching the UI design
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the current selected index for the bottom nav
    // For now, we are just building the UI, so it's static
    final selectedIndex = 0;

    // Watch project stats
    final projectStatsAsync = ref.watch(projectStatsProvider);

    // Watch project list for "Active Projects" section
    final projectListState = ref.watch(projectListProvider);
    final activeProjects = projectListState.projects
        .where((p) => p.status == ProjectStatus.inProgress)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              _buildHeader(context, ref),
              const SizedBox(height: 24),

              // 2. Stats Cards
              Row(
                children: [
                  Expanded(
                    child: projectStatsAsync.when(
                      data: (stats) => _buildBlueStatCard(
                        count: stats['in_progress'] ?? 0,
                        label: 'Active Projects',
                        isLoading: false,
                      ),
                      loading: () => _buildBlueStatCard(isLoading: true),
                      error: (_, __) => _buildBlueStatCard(
                        count: 0,
                        label: 'Error',
                        isLoading: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildWhiteStatCard()),
                ],
              ),
              const SizedBox(height: 32),

              // 3. Operations Section
              const Text(
                'Operations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOperationCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Materials',
                      subtitle: '5 Vendors',
                      color: const Color(0xFFE0EAFF), // Light Blue
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOperationCard(
                      icon: Icons.build_outlined,
                      title: 'Machinery',
                      subtitle: '12 Units',
                      color: const Color(0xFFFFF7ED), // Light Orange
                      iconColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOperationCard(
                      icon: Icons.engineering_outlined,
                      title: 'Labor',
                      subtitle: '142 Workers',
                      color: const Color(0xFFECFDF5), // Light Green
                      iconColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 4. Active Projects Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Projects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/projects'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (projectListState.isLoading && activeProjects.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (activeProjects.isEmpty)
                _buildEmptyProjectState()
              else
                ...activeProjects.map(
                  (project) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildProjectCard(
                      category:
                          project.location ??
                          'Unknown Location', // Handle nullable location
                      title: project.name,
                      progress: 0.65, // TODO: Add progress to ProjectModel
                      isActive: true,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // 5. Recent Operations Section
              const Text(
                'Recent Operations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRecentOperationItem(
                      icon: Icons.inventory_2,
                      iconBgColor: const Color(0xFFF3F4F6),
                      iconColor: const Color(
                        0xFF6B7280,
                      ), // Brownish in image, let's stick to generic or match image
                      // Image shows a brown box.
                      customIcon: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: const Icon(
                          Icons.inventory,
                          color: Color(0xFF8D6E63),
                          size: 20,
                        ),
                      ),
                      title: 'Material Received',
                      subtitle: '500 bags of cement delivered to Skyline',
                      time: '10 mins ago',
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildRecentOperationItem(
                      icon: Icons.warning_amber_rounded,
                      iconBgColor: const Color(0xFFFEF2F2),
                      iconColor: AppColors.error,
                      title: 'Labor Shortage',
                      subtitle: 'Unskilled workers count below threshold',
                      time: '1 hr ago',
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildRecentOperationItem(
                      icon: Icons.description_outlined,
                      iconBgColor: const Color(0xFFFFFBEB),
                      iconColor: AppColors.warning, // Yellowish
                      title: 'New Drawing',
                      subtitle: 'Admin uploaded Block C floor plan',
                      time: '3 hrs ago',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // Handle navigation
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.construction),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Managers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Admin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Notification Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        // Profile Pic
        GestureDetector(
          onTap: () {
            // Sign out logic for demo
            ref.read(authProvider.notifier).signOut();
            context.go('/login');
          },
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?u=admin',
            ), // Placeholder
            backgroundColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBlueStatCard({
    int count = 0,
    String label = 'Active Projects',
    bool isLoading = false,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        gradient: AppStyles.primaryGradient,
        boxShadow: AppStyles.primaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+12%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: AppStyles.statLabel),
          const SizedBox(height: 4),
          isLoading
              ? const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  count.toString().padLeft(2, '0'),
                  style: AppStyles.statCount,
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyProjectState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No active projects',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteStatCard() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Light Blue bg
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const Spacer(),
          const Text(
            'Total Workers',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '142',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyles.smallShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppStyles.cardTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: AppStyles.cardSubtitle),
        ],
      ),
    );
  }

  Widget _buildProjectCard({
    required String category,
    required String title,
    required double progress,
    required bool isActive,
    Color progressColor = AppColors.primary,
    bool hasAddButton = false,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(
            bottom: 8,
          ), // Margin for potential shadow/add button
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppStyles.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category, style: AppStyles.cardSubtitle),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: AppStyles.cardTitle.copyWith(fontSize: 16)),
              if (progress > 0) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Progress',
                      style: AppStyles.cardSubtitle,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
                  ),
                ),
              ] else ...[
                // If no progress shown, maybe keep spacing or minimize
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        if (hasAddButton)
          Positioned(
            right: 16,
            bottom: 24, // Adjusted position to overlap nicely
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentOperationItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    Widget? customIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: customIcon ?? Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
