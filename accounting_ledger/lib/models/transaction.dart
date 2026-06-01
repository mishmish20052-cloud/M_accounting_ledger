// lib/models/transaction.dart
import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String type; // income, expense, transfer
  final double amount;
  final String currency;
  final String accountId;
  final String? toAccountId; // for transfer
  final String category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final bool isRecurring;
  final String? recurringFrequency; // daily, weekly, monthly, yearly
  final DateTime? recurringEndDate;
  final bool isInstallment;
  final String? installmentParentId;
  final int? installmentNumber;
  final int? totalInstallments;
  final String? attachmentPath;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    this.currency = 'USD',
    required this.accountId,
    this.toAccountId,
    required this.category,
    this.description,
    DateTime? date,
    DateTime? createdAt,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringEndDate,
    this.isInstallment = false,
    this.installmentParentId,
    this.installmentNumber,
    this.totalInstallments,
    this.attachmentPath,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Transaction copyWith({
    String? type,
    double? amount,
    String? currency,
    String? accountId,
    String? toAccountId,
    String? category,
    String? description,
    DateTime? date,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? recurringEndDate,
    bool? isInstallment,
    String? installmentParentId,
    int? installmentNumber,
    int? totalInstallments,
    String? attachmentPath,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      isInstallment: isInstallment ?? this.isInstallment,
      installmentParentId: installmentParentId ?? this.installmentParentId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'currency': currency,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_frequency': recurringFrequency,
      'recurring_end_date': recurringEndDate?.toIso8601String(),
      'is_installment': isInstallment ? 1 : 0,
      'installment_parent_id': installmentParentId,
      'installment_number': installmentNumber,
      'total_installments': totalInstallments,
      'attachment_path': attachmentPath,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      accountId: map['account_id'] as String,
      toAccountId: map['to_account_id'] as String?,
      category: map['category'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurringFrequency: map['recurring_frequency'] as String?,
      recurringEndDate: map['recurring_end_date'] != null
          ? DateTime.parse(map['recurring_end_date'] as String)
          : null,
      isInstallment: (map['is_installment'] as int? ?? 0) == 1,
      installmentParentId: map['installment_parent_id'] as String?,
      installmentNumber: map['installment_number'] as int?,
      totalInstallments: map['total_installments'] as int?,
      attachmentPath: map['attachment_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Transaction.fromJson(Map<String, dynamic> json) =>
      Transaction.fromMap(json);
}
