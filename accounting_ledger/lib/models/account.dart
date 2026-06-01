// lib/models/account.dart
import 'package:uuid/uuid.dart';

class Account {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Account({
    String? id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.currency = 'USD',
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Account copyWith({
    String? name,
    String? type,
    double? balance,
    String? currency,
    String? description,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Account.fromJson(Map<String, dynamic> json) => Account.fromMap(json);

  @override
  String toString() => 'Account(id: $id, name: $name, type: $type, balance: $balance)';
}
