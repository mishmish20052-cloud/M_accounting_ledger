// lib/controllers/backup_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';
import 'account_controller.dart';
import 'transaction_controller.dart';

class BackupState {
  final bool isLoading;
  final String? lastBackupPath;
  final String? error;
  final String? successMessage;

  const BackupState({
    this.isLoading = false,
    this.lastBackupPath,
    this.error,
    this.successMessage,
  });

  BackupState copyWith({
    bool? isLoading,
    String? lastBackupPath,
    String? error,
    String? successMessage,
  }) {
    return BackupState(
      isLoading: isLoading ?? this.isLoading,
      lastBackupPath: lastBackupPath ?? this.lastBackupPath,
      error: error,
      successMessage: successMessage,
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  final Ref _ref;
  BackupNotifier(this._ref) : super(const BackupState());

  Future<void> createBackup() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final path = await BackupService.createBackup();
      state = state.copyWith(
        isLoading: false,
        lastBackupPath: path,
        successMessage: 'Backup created: $path',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> restoreFromPicker() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final path = await BackupService.pickBackupFile();
      if (path == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      await BackupService.restoreFromFile(path);
      _ref.read(accountProvider.notifier).loadAccounts();
      _ref.read(transactionProvider.notifier).loadTransactions();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Restore successful from $path',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> restoreFromPath(String path) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await BackupService.restoreFromFile(path);
      _ref.read(accountProvider.notifier).loadAccounts();
      _ref.read(transactionProvider.notifier).loadTransactions();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Restore successful',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>(
  (ref) => BackupNotifier(ref),
);
