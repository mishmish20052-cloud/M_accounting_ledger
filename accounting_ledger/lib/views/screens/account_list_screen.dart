// lib/views/screens/account_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/account_controller.dart';
import '../../models/account.dart';
import '../../models/currency.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance,
                      size: 72,
                      color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No accounts yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAccountDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            itemBuilder: (_, i) => _AccountCard(
              account: list[i],
              onEdit: () => _showAccountDialog(context, ref, account: list[i]),
              onDelete: () => _confirmDelete(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAccountDialog(BuildContext context, WidgetRef ref,
      {Account? account}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AccountFormSheet(account: account, ref: ref),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content:
            Text('Are you sure you want to delete "${account.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(accountProvider.notifier).deleteAccount(account.id);
    }
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = account.balance >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor:
              theme.colorScheme.primaryContainer,
          child: Icon(_iconForType(account.type),
              color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(account.name,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(account.type,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helpers.formatCurrency(account.balance, account.currency),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor,
                  ),
                ),
                Text(account.currency,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4))),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'creditCard':
        return Icons.credit_card;
      case 'loan':
        return Icons.handshake;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

class _AccountFormSheet extends StatefulWidget {
  final Account? account;
  final WidgetRef ref;

  const _AccountFormSheet({this.account, required this.ref});

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _descCtrl;
  late String _type;
  late String _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _balanceCtrl =
        TextEditingController(text: a?.balance.toStringAsFixed(2) ?? '0.00');
    _descCtrl = TextEditingController(text: a?.description ?? '');
    _type = a?.type ?? AppConstants.bank;
    _currency = a?.currency ?? AppConstants.defaultCurrency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final account = Account(
        id: widget.account?.id,
        name: _nameCtrl.text.trim(),
        type: _type,
        balance: double.tryParse(_balanceCtrl.text) ?? 0,
        currency: _currency,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        createdAt: widget.account?.createdAt,
      );
      if (widget.account == null) {
        await widget.ref
            .read(accountProvider.notifier)
            .addAccount(account);
      } else {
        await widget.ref
            .read(accountProvider.notifier)
            .updateAccount(account);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.account != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit Account' : 'Add Account',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Account Name',
                      prefixIcon: Icon(Icons.label_outline)),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                      labelText: 'Account Type',
                      prefixIcon: Icon(Icons.category_outlined)),
                  items: [
                    AppConstants.bank,
                    AppConstants.cash,
                    AppConstants.creditCard,
                    AppConstants.loan,
                    AppConstants.investment,
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _balanceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Initial Balance',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.attach_money)),
                  items: Currency.defaultCurrencies
                      .map((c) => DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.code} - ${c.name}')))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes)),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'Update' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
