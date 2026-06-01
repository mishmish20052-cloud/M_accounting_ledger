// lib/controllers/account_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AccountNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  AccountNotifier() : super(const AsyncValue.loading()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = const AsyncValue.loading();
    try {
      final accounts = await DatabaseService.getAccounts();
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAccount(Account account) async {
    await DatabaseService.insertAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(Account account) async {
    await DatabaseService.updateAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await DatabaseService.deleteAccount(id);
    await loadAccounts();
  }

  double get totalBalance {
    return state.valueOrNull?.fold<double>(0, (sum, a) => sum + a.balance) ?? 0;
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AsyncValue<List<Account>>>(
  (ref) => AccountNotifier(),
);

final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountProvider);
  return accounts.valueOrNull?.fold<double>(0, (sum, a) => sum + a.balance) ?? 0;
});
