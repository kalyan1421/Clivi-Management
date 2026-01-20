import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the app
/// Loads values from .env file
class Env {
  // Private constructor to prevent instantiation
  Env._();

  /// Initialize environment variables
  static Future<void> init() async {
    await dotenv.load(fileName: 'assets/.env');
  }

  /// Supabase Project URL
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    return url;
  }

  /// Supabase Anonymous Key
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    return key;
  }

  /// Debug mode flag - controls Supabase debug logging
  static bool get isDebugMode {
    final debug = dotenv.env['DEBUG_MODE'];
    return debug?.toLowerCase() == 'true';
  }

  /// App environment (development, staging, production)
  static String get appEnv {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  /// Check if running in production
  static bool get isProduction => appEnv == 'production';

  /// Check if running in development
  static bool get isDevelopment => appEnv == 'development';

  /// Check if all required environment variables are present
  static bool validate() {
    try {
      supabaseUrl;
      supabaseAnonKey;
      return true;
    } catch (e) {
      return false;
    }
  }
}
