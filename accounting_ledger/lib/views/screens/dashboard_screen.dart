// lib/views/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/account_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/account.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, double> _summary = {'income': 0, 'expense': 0};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final now = DateTime.now();
    final summary = await ref
        .read(transactionProvider.notifier)
        .getSummary(
          from: Helpers.startOfMonth(now),
          to: Helpers.endOfMonth(now),
        );
    if (mounted) setState(() => _summary = summary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = ref.watch(accountProvider);
    final transactions = ref.watch(transactionProvider);
    final totalBalance = ref.watch(totalBalanceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(accountProvider.notifier).loadAccounts();
        ref.read(transactionProvider.notifier).loadTransactions();
        await _loadSummary();
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Dashboard'),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Balance Card
                  _buildBalanceCard(theme, totalBalance),
                  const SizedBox(height: 16),
                  // Monthly Summary
                  _buildMonthlySummary(theme),
                  const SizedBox(height: 16),
                  // Accounts
                  Text('Accounts',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  accounts.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (list) => list.isEmpty
                        ? _emptyAccounts(theme)
                        : _buildAccountsList(list, theme),
                  ),
                  const SizedBox(height: 16),
                  Text('Recent Transactions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Transactions
          transactions.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverToBoxAdapter(child: Text('Error: $e')),
            data: (txns) {
              final accountList =
                  ref.read(accountProvider).valueOrNull ?? [];
              final accountMap = {for (final a in accountList) a.id: a};
              if (txns.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 48,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text('No transactions yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => TransactionTile(
                    transaction: txns[i],
                    accountName: accountMap[txns[i].accountId]?.name,
                  ),
                  childCount: txns.length.clamp(0, 10),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, double balance) {
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Helpers.formatCurrency(balance, 'USD'),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All accounts combined',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(ThemeData theme) {
    final income = _summary['income'] ?? 0;
    final expense = _summary['expense'] ?? 0;
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            theme,
            'Monthly Income',
            income,
            Icons.trending_up,
            AppTheme.incomeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            theme,
            'Monthly Expense',
            expense,
            Icons.trending_down,
            AppTheme.expenseColor,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(ThemeData theme, String label, double amount,
      IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: color),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount.toStringAsFixed(2),
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList(List<Account> accounts, ThemeData theme) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        itemBuilder: (_, i) {
          final a = accounts[i];
          return Card(
            margin: const EdgeInsets.only(right: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a.name,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatCurrency(a.balance, a.currency),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: a.balance >= 0
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(a.type,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyAccounts(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.account_balance,
                  size: 40,
                  color: theme.colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 8),
              Text('No accounts yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
