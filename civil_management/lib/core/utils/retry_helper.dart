import 'dart:async';
import 'dart:math';
import '../config/supabase_client.dart';

/// Retry utility with exponential backoff for transient failures
class RetryHelper {
  /// Execute operation with automatic retry on transient failures
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 10),
    bool Function(Exception)? retryIf,
  }) async {
    int attempt = 0;
    
    while (true) {
      try {
        attempt++;
        return await operation();
      } on Exception catch (e) {
        final shouldRetry = retryIf?.call(e) ?? _isRetryable(e);
        
        if (attempt >= maxAttempts || !shouldRetry) {
          logger.w('Retry exhausted after $attempt attempts: $e');
          rethrow;
        }
        
        // Exponential backoff with jitter
        final baseDelay = initialDelay * pow(2, attempt - 1);
        final jitter = Duration(
          milliseconds: Random().nextInt(500),
        );
        final delay = baseDelay + jitter;
        final cappedDelay = delay > maxDelay ? maxDelay : delay;
        
        logger.i('Retry attempt $attempt/$maxAttempts after ${cappedDelay.inMilliseconds}ms');
        await Future.delayed(cappedDelay);
      }
    }
  }

  /// Check if exception is retryable (network/timeout issues)
  static bool _isRetryable(Exception e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('503') ||
        msg.contains('502') ||
        msg.contains('429') || // Rate limit
        msg.contains('temporarily');
  }
}
