/// Model for vendor payment summary view
class VendorPaymentSummary {
  final String vendorId;
  final String vendorName;
  final String? vendorType;
  final double? creditLimit;
  final int totalInvoices;
  final double totalInvoiceAmount;
  final double totalPaid;
  final double totalBalance;
  final DateTime? lastTransactionDate;

  const VendorPaymentSummary({
    required this.vendorId,
    required this.vendorName,
    this.vendorType,
    this.creditLimit,
    required this.totalInvoices,
    required this.totalInvoiceAmount,
    required this.totalPaid,
    required this.totalBalance,
    this.lastTransactionDate,
  });

  factory VendorPaymentSummary.fromJson(Map<String, dynamic> json) {
    return VendorPaymentSummary(
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String,
      vendorType: json['vendor_type'] as String?,
      creditLimit: json['credit_limit'] != null ? (json['credit_limit'] as num).toDouble() : null,
      totalInvoices: json['total_invoices'] as int? ?? 0,
      totalInvoiceAmount: (json['total_invoice_amount'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      lastTransactionDate: json['last_transaction_date'] != null 
          ? DateTime.parse(json['last_transaction_date'] as String)
          : null,
    );
  }

  /// Calculate utilization percentage if credit limit exists
  double? get creditUtilization {
    if (creditLimit == null || creditLimit == 0) return null;
    return (totalBalance / creditLimit!) * 100;
  }
}

/// Model for vendor stock summary view
class VendorStockSummary {
  final String vendorId;
  final String vendorName;
  final String? vendorType;
  final String? materialName;
  final String? grade;
  final String? projectId;
  final String? projectName;
  final double? lastPrice;
  final DateTime? lastUsedAt;
  final double currentStock;

  const VendorStockSummary({
    required this.vendorId,
    required this.vendorName,
    this.vendorType,
    this.materialName,
    this.grade,
    this.projectId,
    this.projectName,
    this.lastPrice,
    this.lastUsedAt,
    required this.currentStock,
  });

  factory VendorStockSummary.fromJson(Map<String, dynamic> json) {
    return VendorStockSummary(
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String,
      vendorType: json['vendor_type'] as String?,
      materialName: json['material_name'] as String?,
      grade: json['grade'] as String?,
      projectId: json['project_id'] as String?,
      projectName: json['project_name'] as String?,
      lastPrice: json['last_price'] != null ? (json['last_price'] as num).toDouble() : null,
      lastUsedAt: json['last_used_at'] != null 
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model for project inventory summary view
class ProjectInventorySummary {
  final String projectId;
  final String projectName;
  final String? category; // 'Steel', 'Cement'
  final String? materialName;
  final String? grade;
  final String? unit;
  final double totalQuantity;
  final double? avgUnitPrice;
  final double totalValue;

  const ProjectInventorySummary({
    required this.projectId,
    required this.projectName,
    this.category,
    this.materialName,
    this.grade,
    this.unit,
    required this.totalQuantity,
    this.avgUnitPrice,
    required this.totalValue,
  });

  factory ProjectInventorySummary.fromJson(Map<String, dynamic> json) {
    return ProjectInventorySummary(
      projectId: json['project_id'] as String,
      projectName: json['project_name'] as String,
      category: json['category'] as String?,
      materialName: json['material_name'] as String?,
      grade: json['grade'] as String?,
      unit: json['unit'] as String?,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      avgUnitPrice: json['avg_unit_price'] != null ? (json['avg_unit_price'] as num).toDouble() : null,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
