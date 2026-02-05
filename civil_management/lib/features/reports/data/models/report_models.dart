/// Reports and Analytics Models

/// Financial Statistics Model
/// Matches the JSON returned by get_financial_metrics RPC
class FinancialStats {
  final double totalExpenses;
  final double growthPercentage;
  final double laborCost;
  final double materialCost;
  final double machineryCost;
  final double otherCost;
  final List<ChartDataPoint> chartData;

  const FinancialStats({
    this.totalExpenses = 0,
    this.growthPercentage = 0,
    this.laborCost = 0,
    this.materialCost = 0,
    this.machineryCost = 0,
    this.otherCost = 0,
    this.chartData = const [],
  });

  factory FinancialStats.fromJson(Map<String, dynamic> json) {
    return FinancialStats(
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0,
      growthPercentage: (json['growth_percentage'] as num?)?.toDouble() ?? 0,
      laborCost: (json['labor_cost'] as num?)?.toDouble() ?? 0,
      materialCost: (json['material_cost'] as num?)?.toDouble() ?? 0,
      machineryCost: (json['machinery_cost'] as num?)?.toDouble() ?? 0,
      otherCost: (json['other_cost'] as num?)?.toDouble() ?? 0,
      chartData: (json['chart_data'] as List?)
          ?.map((e) => ChartDataPoint.fromJson(e))
          .toList() ??
          [],
    );
  }

  /// Empty state
  static const empty = FinancialStats();
}

/// Data point for charts
class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({
    required this.label,
    required this.value,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Time Period Filter Enum
enum TimePeriod {
  monthly('Monthly', 'monthly'),
  quarterly('Quarterly', 'quarterly'),
  yearly('Yearly', 'yearly');

  final String label;
  final String value;
  const TimePeriod(this.label, this.value);
}
