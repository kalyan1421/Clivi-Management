import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/retry_helper.dart';
import '../models/models.dart';

/// Repository for all authentication-related Supabase operations
/// Follows the Repository Pattern - all Supabase calls go through here
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client}) : _client = client ?? supabase;

  // ============================================================
  // AUTH OPERATIONS
  // ============================================================

  /// Sign in with email and password
  Future<AuthResultModel> signIn(SignInRequest request) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: request.email,
        password: request.password,
      );

      if (response.user == null) {
        return AuthResultModel.failure('Sign in failed');
      }

      // Fetch user profile
      final profile = await getUserProfile(response.user!.id);

      logger.i('User signed in: ${response.user!.email}');

      return AuthResultModel.success(
        user: response.user!,
        session: response.session,
        profile: profile,
      );
    } on AuthException catch (e) {
      logger.e('Sign in failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    } catch (e) {
      logger.e('Sign in error: $e');
      throw AppAuthException('An unexpected error occurred during sign in');
    }
  }

  /// Sign up with email and password
  Future<AuthResultModel> signUp(SignUpRequest request) async {
    try {
      // Sign up with user metadata (trigger will create profile automatically)
      final response = await _client.auth.signUp(
        email: request.email,
        password: request.password,
        data: {'full_name': request.fullName, 'phone': request.phone},
      );

      if (response.user == null) {
        return AuthResultModel.failure('Sign up failed');
      }

      logger.i('User signed up: ${response.user!.email}');

      // Use RetryHelper with exponential backoff to wait for trigger-created profile
      final userId = response.user!.id;
      
      final profile = await RetryHelper.retryUntil<UserProfileModel>(
        () => getUserProfile(userId),
        (result) => result != null,
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 2),
      );

      // Update profile with additional info if provided and profile exists
      UserProfileModel? finalProfile = profile;
      if (profile != null && (request.fullName != null || request.phone != null)) {
        final updates = <String, dynamic>{};
        if (request.fullName != null) updates['full_name'] = request.fullName;
        if (request.phone != null) updates['phone'] = request.phone;

        if (updates.isNotEmpty) {
          try {
            finalProfile = await updateUserProfile(
              userId: userId,
              updates: updates,
            );
          } catch (e) {
            logger.w('Could not update profile with additional info: $e');
            // Continue with original profile
          }
        }
      }

      return AuthResultModel.success(
        user: response.user!,
        session: response.session,
        profile: finalProfile,
      );
    } on AuthException catch (e) {
      logger.e('Sign up failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    } catch (e) {
      logger.e('Sign up error: $e');
      throw AppAuthException('An unexpected error occurred during sign up');
    }
  }

  /// Create a new user as admin without affecting the current session
  /// This preserves the admin's login state while creating the new user
  Future<UserProfileModel> createUserAsAdmin({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    String role = 'site_manager',
  }) async {
    // Save current admin session
    final adminSession = currentSession;
    final adminAccessToken = adminSession?.accessToken;
    final adminRefreshToken = adminSession?.refreshToken;
    
    if (adminSession == null) {
      throw AppAuthException('Admin must be logged in to create users');
    }

    try {
      // Create the new user (this will temporarily switch the session)
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (response.user == null) {
        throw AppAuthException('Failed to create user account');
      }

      final newUserId = response.user!.id;
      logger.i('Created new user: $email');

      // Immediately restore admin session
      await _client.auth.setSession(adminRefreshToken!);
      logger.i('Admin session restored');

      // Use RetryHelper to wait for profile to be created by trigger
      final createdProfile = await RetryHelper.retryUntil<UserProfileModel>(
        () => getUserProfile(newUserId),
        (result) => result != null,
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 2),
      );

      // Update the new user's profile with role and details
      try {
        final profile = await updateUserProfile(
          userId: newUserId,
          updates: {
            'role': role,
            'full_name': fullName,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
        return profile;
      } catch (e) {
        // If profile doesn't exist yet, create it
        logger.w('Profile not found, creating: $e');
        final profile = await createUserProfile({
          'id': newUserId,
          'email': email,
          'role': role,
          'full_name': fullName,
          'phone': phone,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        return profile;
      }
    } on AuthException catch (e) {
      // Try to restore admin session on error
      if (adminRefreshToken != null) {
        try {
          await _client.auth.setSession(adminRefreshToken);
        } catch (_) {}
      }
      logger.e('Create user failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    } catch (e) {
      // Try to restore admin session on error
      if (adminRefreshToken != null) {
        try {
          await _client.auth.setSession(adminRefreshToken);
        } catch (_) {}
      }
      logger.e('Create user error: $e');
      throw AppAuthException('An unexpected error occurred while creating user');
    }
  }


  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      logger.i('User signed out');
    } catch (e) {
      logger.e('Sign out error: $e');
      throw AppAuthException('Failed to sign out');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(PasswordResetRequest request) async {
    try {
      await _client.auth.resetPasswordForEmail(request.email);
      logger.i('Password reset email sent to: ${request.email}');
    } on AuthException catch (e) {
      logger.e('Password reset failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    }
  }

  /// Update user password
  Future<void> updatePassword(PasswordUpdateRequest request) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: request.newPassword),
      );
      logger.i('Password updated successfully');
    } on AuthException catch (e) {
      logger.e('Password update failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    }
  }

  /// Refresh current session
  Future<Session?> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      logger.i('Session refreshed');
      return response.session;
    } catch (e) {
      logger.e('Session refresh failed: $e');
      return null;
    }
  }

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============================================================
  // PROFILE OPERATIONS
  // ============================================================

  /// Get user profile by ID
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        logger.w('User profile not found for: $userId');
        return null;
      }

      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch user profile: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Create user profile
  Future<UserProfileModel> createUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _client
          .from('user_profiles')
          .insert(profileData)
          .select()
          .single();

      logger.i('User profile created');
      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to create user profile: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update user profile
  Future<UserProfileModel> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      logger.i('User profile updated');
      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to update user profile: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      await _client
          .from('user_profiles')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      logger.i('User role updated to: $newRole');
    } on PostgrestException catch (e) {
      logger.e('Failed to update user role: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get all users (admin only)
  Future<List<UserProfileModel>> getAllUsers() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfileModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch users: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get users by role
  Future<List<UserProfileModel>> getUsersByRole(String role) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfileModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch users by role: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }
}
