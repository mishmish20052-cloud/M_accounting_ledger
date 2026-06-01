// lib/models/installment.dart
import 'package:uuid/uuid.dart';

class Installment {
  final String id;
  final String name;
  final double totalAmount;
  final int numberOfInstallments;
  final double installmentAmount;
  final String currency;
  final String accountId;
  final String category;
  final DateTime startDate;
  final String frequency; // monthly, weekly, etc.
  final int paidCount;
  final bool isCompleted;
  final DateTime createdAt;

  Installment({
    String? id,
    required this.name,
    required this.totalAmount,
    required this.numberOfInstallments,
    required this.installmentAmount,
    this.currency = 'USD',
    required this.accountId,
    required this.category,
    DateTime? startDate,
    this.frequency = 'monthly',
    this.paidCount = 0,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  double get remainingAmount =>
      totalAmount - (installmentAmount * paidCount);

  int get remainingCount => numberOfInstallments - paidCount;

  DateTime get nextDueDate {
    if (frequency == 'weekly') {
      return startDate.add(Duration(days: 7 * paidCount));
    } else if (frequency == 'monthly') {
      return DateTime(
          startDate.year, startDate.month + paidCount, startDate.day);
    } else if (frequency == 'yearly') {
      return DateTime(startDate.year + paidCount, startDate.month, startDate.day);
    }
    return startDate.add(Duration(days: 30 * paidCount));
  }

  Installment copyWith({
    String? name,
    double? totalAmount,
    int? numberOfInstallments,
    double? installmentAmount,
    String? currency,
    String? accountId,
    String? category,
    DateTime? startDate,
    String? frequency,
    int? paidCount,
    bool? isCompleted,
  }) {
    return Installment(
      id: id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      paidCount: paidCount ?? this.paidCount,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'total_amount': totalAmount,
      'number_of_installments': numberOfInstallments,
      'installment_amount': installmentAmount,
      'currency': currency,
      'account_id': accountId,
      'category': category,
      'start_date': startDate.toIso8601String(),
      'frequency': frequency,
      'paid_count': paidCount,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    return Installment(
      id: map['id'] as String,
      name: map['name'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      numberOfInstallments: map['number_of_installments'] as int,
      installmentAmount: (map['installment_amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      accountId: map['account_id'] as String,
      category: map['category'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      frequency: map['frequency'] as String? ?? 'monthly',
      paidCount: map['paid_count'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Installment.fromJson(Map<String, dynamic> json) =>
      Installment.fromMap(json);
}
