// lib/views/widgets/transaction_tile.dart
import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String? accountName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.accountName,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final amountColor = isTransfer
        ? AppTheme.transferColor
        : isIncome
            ? AppTheme.incomeColor
            : AppTheme.expenseColor;
    final amountPrefix = isTransfer ? '↔' : isIncome ? '+' : '-';
    final icon = _iconForCategory(transaction.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.15),
          child: Icon(icon, color: amountColor, size: 20),
        ),
        title: Text(
          transaction.category,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              Text(
                Helpers.truncate(transaction.description!, 40),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            Text(
              '${accountName ?? ''} • ${Helpers.formatDate(transaction.date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            if (transaction.isRecurring)
              Row(
                children: [
                  Icon(Icons.repeat,
                      size: 12,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    transaction.recurringFrequency ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$amountPrefix ${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18,
                    color: theme.colorScheme.error.withOpacity(0.7)),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.electrical_services;
      case 'rent':
        return Icons.home;
      case 'salary':
        return Icons.work;
      case 'investment':
        return Icons.trending_up;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.receipt_long;
    }
  }
}
