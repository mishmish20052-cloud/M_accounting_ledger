// lib/controllers/transaction_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/installment.dart';
import '../services/database_service.dart';
import 'account_controller.dart';

class TransactionFilter {
  final String? accountId;
  final DateTime? from;
  final DateTime? to;
  final String? type;
  final int? limit;

  const TransactionFilter({
    this.accountId,
    this.from,
    this.to,
    this.type,
    this.limit,
  });
}

class TransactionNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  final Ref _ref;
  TransactionFilter _filter = const TransactionFilter(limit: 50);

  TransactionNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions({TransactionFilter? filter}) async {
    if (filter != null) _filter = filter;
    state = const AsyncValue.loading();
    try {
      final txns = await DatabaseService.getTransactions(
        accountId: _filter.accountId,
        from: _filter.from,
        to: _filter.to,
        type: _filter.type,
        limit: _filter.limit,
      );
      state = AsyncValue.data(txns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await DatabaseService.insertTransaction(transaction);
    // Update account balance
    final account =
        await DatabaseService.getAccountById(transaction.accountId);
    if (account != null) {
      double newBalance = account.balance;
      if (transaction.type == 'income') {
        newBalance += transaction.amount;
      } else if (transaction.type == 'expense') {
        newBalance -= transaction.amount;
      } else if (transaction.type == 'transfer') {
        newBalance -= transaction.amount;
      }
      await DatabaseService.updateAccountBalance(account.id, newBalance);
    }

    if (transaction.type == 'transfer' && transaction.toAccountId != null) {
      final toAccount =
          await DatabaseService.getAccountById(transaction.toAccountId!);
      if (toAccount != null) {
        await DatabaseService.updateAccountBalance(
            toAccount.id, toAccount.balance + transaction.amount);
      }
    }

    _ref.read(accountProvider.notifier).loadAccounts();
    await loadTransactions();
  }

  Future<void> addInstallmentTransactions(
      Installment installment, int installmentsToAdd) async {
    for (var i = 0; i < installmentsToAdd; i++) {
      DateTime dueDate;
      if (installment.frequency == 'weekly') {
        dueDate = installment.startDate.add(Duration(days: 7 * i));
      } else if (installment.frequency == 'monthly') {
        dueDate = DateTime(installment.startDate.year,
            installment.startDate.month + i, installment.startDate.day);
      } else {
        dueDate = installment.startDate.add(Duration(days: 30 * i));
      }

      final txn = Transaction(
        type: 'expense',
        amount: installment.installmentAmount,
        currency: installment.currency,
        accountId: installment.accountId,
        category: installment.category,
        description: '${installment.name} - Installment ${i + 1}/${installment.numberOfInstallments}',
        date: dueDate,
        isInstallment: true,
        installmentParentId: installment.id,
        installmentNumber: i + 1,
        totalInstallments: installment.numberOfInstallments,
      );
      await DatabaseService.insertTransaction(txn);
    }
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await DatabaseService.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseService.deleteTransaction(id);
    await loadTransactions();
  }

  Future<Map<String, double>> getSummary({DateTime? from, DateTime? to}) async {
    return DatabaseService.getSummary(from: from, to: to);
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier,
    AsyncValue<List<Transaction>>>(
  (ref) => TransactionNotifier(ref),
);

final installmentProvider =
    FutureProvider<List<Installment>>((ref) async {
  return DatabaseService.getInstallments();
});
