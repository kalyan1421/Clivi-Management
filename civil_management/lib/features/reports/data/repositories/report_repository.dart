import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/report_models.dart';

/// Repository for Reports and Analytics
class ReportRepository {
  final SupabaseClient _client;

  ReportRepository({SupabaseClient? client}) : _client = client ?? supabase;

  /// Fetch financial metrics for a specific period and optional project
  Future<FinancialStats> getFinancialMetrics({
    required TimePeriod period,
    String? projectId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_financial_metrics',
        params: {
          'p_period': period.value,
          'p_project_id_text': projectId,
        },
      );

      if (response == null) {
        return FinancialStats.empty;
      }

      return FinancialStats.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch financial metrics: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      logger.e('Unexpected error fetching financial metrics: $e');
      throw Exception('Failed to load reports: $e');
    }
  }
}
