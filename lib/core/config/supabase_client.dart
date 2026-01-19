import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'env.dart';

/// Global Supabase client instance
final supabase = Supabase.instance.client;

/// Logger for debugging
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 75,
    colors: true,
    printEmojis: true,
  ),
);

/// Initialize Supabase with environment configuration
class SupabaseConfig {
  // Private constructor
  SupabaseConfig._();

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      logger.i('Initializing Supabase...');
      logger.i('Environment: ${Env.appEnv}');

      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        debug: Env.isDebugMode, // Controlled by .env DEBUG_MODE
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );

      logger.i('Supabase initialized successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => supabase.auth.currentSession != null;

  /// Get current user
  static User? get currentUser => supabase.auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => supabase.auth.currentUser?.id;

  /// Sign out
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      logger.i('User signed out successfully');
    } catch (e, stackTrace) {
      logger.e('Sign out failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
