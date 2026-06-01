// lib/views/screens/backup_restore_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/backup_controller.dart';
import '../../services/backup_service.dart';
import '../../utils/helpers.dart';
import '../widgets/loading_overlay.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState
    extends ConsumerState<BackupRestoreScreen> {
  List<FileSystemEntity> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final list = await BackupService.listBackups();
    if (mounted) setState(() => _backups = list);
  }

  Future<void> _createBackup() async {
    await ref.read(backupProvider.notifier).createBackup();
    await _loadBackups();
    final state = ref.read(backupProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.error ?? state.successMessage ?? 'Done'),
        backgroundColor:
            state.error != null ? Colors.red : Colors.green,
      ));
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
            'This will replace all current data. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(backupProvider.notifier).restoreFromPicker();
    await _loadBackups();
    final state = ref.read(backupProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.error ?? state.successMessage ?? 'Done'),
        backgroundColor:
            state.error != null ? Colors.red : Colors.green,
      ));
    }
  }

  Future<void> _restoreFromFile(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore this Backup?'),
        content: Text(
            'File: ${path.split('/').last}\n\nThis will replace all current data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(backupProvider.notifier).restoreFromPath(path);
    final state = ref.read(backupProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.error ?? state.successMessage ?? 'Done'),
        backgroundColor:
            state.error != null ? Colors.red : Colors.green,
      ));
    }
  }

  Future<void> _deleteBackup(String path) async {
    await BackupService.deleteBackup(path);
    await _loadBackups();
  }

  Future<void> _shareBackup(String path) async {
    await Share.shareXFiles([XFile(path)],
        text: 'Accounting Ledger Backup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backup = ref.watch(backupProvider);

    return LoadingOverlay(
      isLoading: backup.isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Backup & Restore')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Actions card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Data Management',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createBackup,
                      icon: const Icon(Icons.backup_outlined),
                      label: const Text('Create Backup Now'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _restore,
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restore from File'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Backup History',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_backups.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.3)),
                        const SizedBox(height: 8),
                        Text('No backups yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5))),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._backups.map((f) {
                final name = f.path.split('/').last;
                final stat = File(f.path).statSync();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(name,
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      Helpers.formatDateTime(stat.modified),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore,
                              color: Colors.orange),
                          tooltip: 'Restore',
                          onPressed: () =>
                              _restoreFromFile(f.path),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.share_outlined),
                          tooltip: 'Share',
                          onPressed: () =>
                              _shareBackup(f.path),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () =>
                              _deleteBackup(f.path),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
