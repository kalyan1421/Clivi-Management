import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum BillStatus {
  pending('pending'),
  approved('approved'),
  paid('paid'),
  rejected('rejected');

  final String value;
  const BillStatus(this.value);

  static BillStatus fromString(String? status) {
    return BillStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => BillStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.approved:
        return 'Approved';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case BillStatus.pending:
        return AppColors.warning;
      case BillStatus.approved:
        return AppColors.info;
      case BillStatus.paid:
        return AppColors.success;
      case BillStatus.rejected:
        return AppColors.error;
    }
  }
}

enum BillType {
  expense('expense'),
  income('income'),
  invoice('invoice');

  final String value;
  const BillType(this.value);

  static BillType fromString(String? type) {
    return BillType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => BillType.expense,
    );
  }

  String get label {
    switch (this) {
      case BillType.expense:
        return 'Expense';
      case BillType.income:
        return 'Income';
      case BillType.invoice:
        return 'Invoice';
    }
  }
}

class BillModel {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final double amount;
  final BillType type;
  final BillStatus status;
  final DateTime billDate;
  final DateTime? dueDate;
  final String? vendorName;
  final String? receiptUrl;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? createdAt;

  // Joined data (optional)
  final String? projectName;
  final String? createdByName;

  const BillModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.amount,
    this.type = BillType.expense,
    this.status = BillStatus.pending,
    required this.billDate,
    this.dueDate,
    this.vendorName,
    this.receiptUrl,
    this.createdBy,
    this.approvedBy,
    this.createdAt,
    this.projectName,
    this.createdByName,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: BillType.fromString(json['bill_type'] as String?),
      status: BillStatus.fromString(json['status'] as String?),
      billDate: DateTime.parse(json['bill_date'] as String),
      dueDate:
          json['due_date'] != null
              ? DateTime.parse(json['due_date'] as String)
              : null,
      vendorName: json['vendor_name'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      createdBy: json['created_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      projectName:
          json['projects'] != null ? json['projects']['name'] as String? : null,
      createdByName:
          json['user_profiles'] != null
              ? json['user_profiles']['full_name'] as String?
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'description': description,
      'amount': amount,
      'bill_type': type.value,
      'status': status.value,
      'bill_date': billDate.toIso8601String().split('T').first,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'vendor_name': vendorName,
      'receipt_url': receiptUrl,
      'created_by': createdBy,
      'approved_by': approvedBy,
    };
  }

  BillModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    double? amount,
    BillType? type,
    BillStatus? status,
    DateTime? billDate,
    DateTime? dueDate,
    String? vendorName,
    String? receiptUrl,
    String? createdBy,
    String? approvedBy,
  }) {
    return BillModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      billDate: billDate ?? this.billDate,
      dueDate: dueDate ?? this.dueDate,
      vendorName: vendorName ?? this.vendorName,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt,
      projectName: projectName,
      createdByName: createdByName,
    );
  }
}
