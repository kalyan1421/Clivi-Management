import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/super_admin_dashboard.dart';
import '../../features/dashboard/screens/admin_dashboard.dart';
import '../../features/dashboard/screens/site_manager_dashboard.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/projects/screens/project_list_screen.dart';
import '../../features/projects/screens/create_project_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/blueprints/screens/blueprints_folders_screen.dart';
import '../../features/blueprints/screens/blueprint_files_screen.dart';
import '../../features/blueprints/screens/blueprint_viewer_screen.dart';
import '../../features/blueprints/data/models/blueprint_model.dart';
import '../../features/projects/data/models/project_model.dart';

/// Global router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);


  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.role;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplashRoute = state.matchedLocation == '/splash';

      // Allow splash screen
      if (isSplashRoute) {
        return null;
      }

      // Public routes that don't require auth
      final publicRoutes = ['/login', '/signup', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // If authenticated and trying to access public auth route, redirect to dashboard
      if (isAuthenticated && isPublicRoute && userRole != null) {
        return _getRoleBasedRoute(userRole);
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Super Admin Routes
      GoRoute(
        path: '/super-admin/dashboard',
        name: 'super-admin-dashboard',
        builder: (context, state) => const SuperAdminDashboard(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),

      // Site Manager Routes
      GoRoute(
        path: '/site-manager/dashboard',
        name: 'site-manager-dashboard',
        builder: (context, state) => const SiteManagerDashboard(),
      ),

      // Project Routes
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: '/projects/create',
        name: 'create-project',
        builder: (context, state) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        name: 'project-detail',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: projectId);
        },
        routes: [
          // Blueprint Routes
          GoRoute(
            path: 'blueprints',
            name: 'project-blueprints',
            builder: (context, state) {
              final project = state.extra as ProjectModel;
              return BlueprintsFoldersScreen(project: project);
            },
          ),
          GoRoute(
            path: 'blueprints/:folderName',
            name: 'project-blueprint-files',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              final folderName = state.pathParameters['folderName']!;
              return BlueprintFilesScreen(projectId: projectId, folderName: folderName);
            },
            routes: [
              GoRoute(
                path: ':fileId',
                name: 'project-blueprint-viewer',
                builder: (context, state) {
                  final blueprint = state.extra as Blueprint;
                  return BlueprintViewerScreen(blueprint: blueprint);
                },
              ),
            ]
          ),
        ]
      ),
      GoRoute(
        path: '/projects/:id/edit',
        name: 'edit-project',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return CreateProjectScreen(projectId: projectId);
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Get dashboard route based on user role
String _getRoleBasedRoute(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return '/super-admin/dashboard';
    case UserRole.admin:
      return '/admin/dashboard';
    case UserRole.siteManager:
      return '/site-manager/dashboard';
  }
}

/// Auth state listener for router refresh
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Router key for navigation without context
final rootNavigatorKey = GlobalKey<NavigatorState>();
