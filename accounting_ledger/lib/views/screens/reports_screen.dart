// lib/views/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/account_controller.dart';
import '../../services/pdf_excel_service.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/loading_overlay.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _from = Helpers.startOfMonth(DateTime.now());
  DateTime _to = Helpers.endOfMonth(DateTime.now());
  String _rangeLabel = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReport() {
    ref.read(reportProvider.notifier).loadReport(from: _from, to: _to);
  }

  Future<void> _setRange(String label, DateTime from, DateTime to) async {
    setState(() {
      _rangeLabel = label;
      _from = from;
      _to = to;
    });
    _loadReport();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Select start date',
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: from,
      lastDate: now,
      helpText: 'Select end date',
    );
    if (to == null) return;
    await _setRange('Custom', from,
        DateTime(to.year, to.month, to.day, 23, 59, 59));
  }

  Future<void> _exportPdf() async {
    final accounts = ref.read(accountProvider).valueOrNull ?? [];
    final path = await ref.read(reportProvider.notifier).exportPdf(
          accounts,
          'Transaction Report - $_rangeLabel',
          from: _from,
          to: _to,
        );
    await PdfExcelService.openFile(path);
  }

  Future<void> _exportExcel() async {
    final accounts = ref.read(accountProvider).valueOrNull ?? [];
    final path = await ref
        .read(reportProvider.notifier)
        .exportExcel(accounts, 'Transaction Report - $_rangeLabel');
    await PdfExcelService.openFile(path);
  }

  Future<void> _sharePdf() async {
    final accounts = ref.read(accountProvider).valueOrNull ?? [];
    final path = await ref.read(reportProvider.notifier).exportPdf(
          accounts,
          'Transaction Report - $_rangeLabel',
          from: _from,
          to: _to,
        );
    await Share.shareXFiles([XFile(path)], text: 'Transaction Report');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = ref.watch(reportProvider);

    return LoadingOverlay(
      isLoading: report.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
            IconButton(
              icon: const Icon(Icons.table_chart_outlined),
              tooltip: 'Export Excel',
              onPressed: _exportExcel,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: _sharePdf,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'By Category'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Date range selector
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Icon(Icons.date_range,
                      size: 18,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _rangeChip('This Month', () => _setRange(
                              'This Month',
                              Helpers.startOfMonth(DateTime.now()),
                              Helpers.endOfMonth(DateTime.now()))),
                          _rangeChip('Last Month', () {
                            final prev = DateTime(DateTime.now().year,
                                DateTime.now().month - 1);
                            _setRange('Last Month',
                                Helpers.startOfMonth(prev),
                                Helpers.endOfMonth(prev));
                          }),
                          _rangeChip('This Year', () => _setRange(
                              'This Year',
                              Helpers.startOfYear(DateTime.now()),
                              Helpers.endOfYear(DateTime.now()))),
                          _rangeChip('Custom', _pickCustomRange),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(report: report),
                  _CategoryTab(report: report),
                  _TransactionsTab(report: report),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(String label, VoidCallback onTap) {
    final selected = _rangeLabel == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ReportState report;
  const _OverviewTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = report.totalIncome;
    final expense = report.totalExpense;
    final net = report.net;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary cards
          Row(
            children: [
              _SummaryCard(
                  label: 'Income',
                  amount: income,
                  color: AppTheme.incomeColor,
                  icon: Icons.trending_up),
              const SizedBox(width: 12),
              _SummaryCard(
                  label: 'Expense',
                  amount: expense,
                  color: AppTheme.expenseColor,
                  icon: Icons.trending_down),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    net >= 0 ? Icons.thumb_up : Icons.thumb_down,
                    color: net >= 0
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Balance',
                          style: theme.textTheme.labelLarge),
                      Text(
                        '${net >= 0 ? '+' : ''}${net.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: net >= 0
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (income > 0 || expense > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PieChartWidget(
                  data: {
                    if (income > 0) 'Income': income,
                    if (expense > 0) 'Expense': expense,
                  },
                  title: 'Income vs Expense',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                amount.toStringAsFixed(2),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final ReportState report;
  const _CategoryTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (report.expensesByCategory.isEmpty) {
      return const Center(child: Text('No expense data for this period'));
    }
    final sorted = report.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (s, e) => s + e.value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PieChartWidget(
              data: report.expensesByCategory,
              title: 'Expenses by Category',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...sorted.map((e) {
          final pct = total > 0 ? e.value / total * 100 : 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${e.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                        style: TextStyle(
                            color: AppTheme.expenseColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: total > 0 ? e.value / total : 0,
                    backgroundColor:
                        theme.colorScheme.surfaceVariant,
                    color: AppTheme.expenseColor,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  final ReportState report;
  const _TransactionsTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (report.transactions.isEmpty) {
      return const Center(child: Text('No transactions in this period'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: report.transactions.length,
      itemBuilder: (_, i) {
        final t = report.transactions[i];
        final isIncome = t.type == 'income';
        final color =
            isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 18),
          ),
          title: Text(t.category,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          subtitle: Text(Helpers.formatDate(t.date)),
          trailing: Text(
            '${isIncome ? '+' : '-'} ${t.currency} ${t.amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
