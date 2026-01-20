import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
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

      // Wait a moment for the trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to fetch the auto-created profile
      UserProfileModel? profile;
      try {
        profile = await getUserProfile(response.user!.id);

        // Update profile with additional info if provided
        if (profile != null &&
            (request.fullName != null || request.phone != null)) {
          final updates = <String, dynamic>{};
          if (request.fullName != null) updates['full_name'] = request.fullName;
          if (request.phone != null) updates['phone'] = request.phone;

          if (updates.isNotEmpty) {
            profile = await updateUserProfile(
              userId: response.user!.id,
              updates: updates,
            );
          }
        }
      } catch (e) {
        logger.w('Could not fetch/update profile after signup: $e');
        // Profile might not exist yet if trigger didn't fire
        // This is okay - profile will be created on first login
      }

      return AuthResultModel.success(
        user: response.user!,
        session: response.session,
        profile: profile,
      );
    } on AuthException catch (e) {
      logger.e('Sign up failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    } catch (e) {
      logger.e('Sign up error: $e');
      throw AppAuthException('An unexpected error occurred during sign up');
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
