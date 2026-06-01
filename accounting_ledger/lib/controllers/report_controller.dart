// lib/controllers/report_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/pdf_excel_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class ReportState {
  final bool isLoading;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> expensesByCategory;
  final List<Transaction> transactions;
  final String? error;

  const ReportState({
    this.isLoading = false,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.expensesByCategory = const {},
    this.transactions = const [],
    this.error,
  });

  double get net => totalIncome - totalExpense;

  ReportState copyWith({
    bool? isLoading,
    double? totalIncome,
    double? totalExpense,
    Map<String, double>? expensesByCategory,
    List<Transaction>? transactions,
    String? error,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      transactions: transactions ?? this.transactions,
      error: error,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier() : super(const ReportState());

  Future<void> loadReport({
    DateTime? from,
    DateTime? to,
    String? accountId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await DatabaseService.getSummary(from: from, to: to);
      final categories =
          await DatabaseService.getExpensesByCategory(from: from, to: to);
      final transactions = await DatabaseService.getTransactions(
        accountId: accountId,
        from: from,
        to: to,
      );
      state = state.copyWith(
        isLoading: false,
        totalIncome: summary['income'] ?? 0,
        totalExpense: summary['expense'] ?? 0,
        expensesByCategory: categories,
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String> exportPdf(List<Account> accounts, String title,
      {DateTime? from, DateTime? to}) async {
    return PdfExcelService.generateTransactionsPdf(
      transactions: state.transactions,
      accounts: accounts,
      title: title,
      from: from,
      to: to,
    );
  }

  Future<String> exportExcel(List<Account> accounts, String title) async {
    return PdfExcelService.generateTransactionsExcel(
      transactions: state.transactions,
      accounts: accounts,
      title: title,
    );
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>(
  (ref) => ReportNotifier(),
);
