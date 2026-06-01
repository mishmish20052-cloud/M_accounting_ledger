// lib/views/screens/transaction_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/account_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import '../../models/installment.dart';
import '../../models/currency.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import '../../services/speech_service.dart';
import '../../utils/constants.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
  String? _accountId;
  String? _toAccountId;
  String _currency = AppConstants.defaultCurrency;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  String _recurringFreq = AppConstants.monthly;
  DateTime? _recurringEndDate;
  bool _isInstallment = false;
  int _installmentCount = 6;
  bool _saving = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _type = t?.type ?? AppConstants.expense;
    _amountCtrl =
        TextEditingController(text: t?.amount.toStringAsFixed(2) ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _categoryCtrl = TextEditingController(text: t?.category ?? '');
    _accountId = t?.accountId;
    _toAccountId = t?.toAccountId;
    _currency = t?.currency ?? AppConstants.defaultCurrency;
    _date = t?.date ?? DateTime.now();
    _isRecurring = t?.isRecurring ?? false;
    _recurringFreq = t?.recurringFrequency ?? AppConstants.monthly;
    _isInstallment = t?.isInstallment ?? false;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories => _type == AppConstants.income
      ? AppConstants.incomeCategories
      : AppConstants.expenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _suggestCategory() async {
    if (_descCtrl.text.trim().isEmpty) return;
    final suggestion = await AiService.suggestCategory(_descCtrl.text);
    if (suggestion != null && mounted) {
      setState(() => _categoryCtrl.text = suggestion);
    }
  }

  Future<void> _startListening() async {
    final ok = await SpeechService.initialize();
    if (!ok) return;
    setState(() => _isListening = true);
    await SpeechService.startListening(
      onResult: (text) {
        if (text.isNotEmpty) {
          _descCtrl.text = text;
          final parsed = AiService.parseTransactionText(text);
          if (parsed['amount'] != null) {
            _amountCtrl.text =
                (parsed['amount'] as double).toStringAsFixed(2);
          }
          if (parsed['type'] != null) {
            setState(() => _type = parsed['type'] as String);
          }
          _suggestCategory();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await SpeechService.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')));
      return;
    }
    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountCtrl.text);

      if (_isInstallment && widget.transaction == null) {
        final inst = Installment(
          name: _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : _categoryCtrl.text.trim(),
          totalAmount: amount,
          numberOfInstallments: _installmentCount,
          installmentAmount: amount / _installmentCount,
          currency: _currency,
          accountId: _accountId!,
          category: _categoryCtrl.text.trim(),
          startDate: _date,
          frequency: _recurringFreq,
        );
        await DatabaseService.insertInstallment(inst);
        await ref
            .read(transactionProvider.notifier)
            .addInstallmentTransactions(inst, _installmentCount);
      } else {
        final txn = Transaction(
          id: widget.transaction?.id,
          type: _type,
          amount: amount,
          currency: _currency,
          accountId: _accountId!,
          toAccountId: _type == AppConstants.transfer ? _toAccountId : null,
          category: _categoryCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          date: _date,
          createdAt: widget.transaction?.createdAt,
          isRecurring: _isRecurring,
          recurringFrequency: _isRecurring ? _recurringFreq : null,
          recurringEndDate: _isRecurring ? _recurringEndDate : null,
        );
        if (widget.transaction == null) {
          await ref
              .read(transactionProvider.notifier)
              .addTransaction(txn);
        } else {
          await ref
              .read(transactionProvider.notifier)
              .updateTransaction(txn);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = ref.watch(accountProvider).valueOrNull ?? [];
    final isEdit = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? theme.colorScheme.error : null,
            ),
            onPressed: _isListening ? _stopListening : _startListening,
            tooltip: 'Voice input',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    AppConstants.expense,
                    AppConstants.income,
                    AppConstants.transfer,
                  ].map((t) {
                    final selected = _type == t;
                    Color color;
                    switch (t) {
                      case 'income':
                        color = Colors.green;
                        break;
                      case 'transfer':
                        color = Colors.blue;
                        break;
                      default:
                        color = Colors.red;
                    }
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = t;
                          _categoryCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: selected ? color : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              t[0].toUpperCase() + t.substring(1),
                              style: TextStyle(
                                color: selected ? color : null,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Amount + Currency
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      if (double.parse(v) <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: Currency.defaultCurrencies
                        .map((c) => DropdownMenuItem(
                            value: c.code, child: Text(c.code)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Account selector
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: const InputDecoration(
                labelText: 'Account',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: accounts
                  .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} (${a.currency})')))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // To account (transfer only)
            if (_type == AppConstants.transfer) ...[
              DropdownButtonFormField<String>(
                value: _toAccountId,
                decoration: const InputDecoration(
                  labelText: 'To Account',
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: accounts
                    .where((a) => a.id != _accountId)
                    .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.name} (${a.currency})')))
                    .toList(),
                onChanged: (v) => setState(() => _toAccountId = v),
                validator: (v) =>
                    _type == AppConstants.transfer && v == null
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 12),
            ],

            // Category
            Autocomplete<String>(
              initialValue:
                  TextEditingValue(text: _categoryCtrl.text),
              optionsBuilder: (val) {
                if (val.text.isEmpty) return _categories;
                return _categories.where((c) => c
                    .toLowerCase()
                    .contains(val.text.toLowerCase()));
              },
              onSelected: (v) => setState(() => _categoryCtrl.text = v),
              fieldViewBuilder:
                  (context, controller, focusNode, onSubmit) {
                _categoryCtrl.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      tooltip: 'AI suggest',
                      onPressed: _suggestCategory,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Date
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                    '${_date.day}/${_date.month}/${_date.year}'),
              ),
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            SwitchListTile(
              title: const Text('Recurring Transaction'),
              subtitle: const Text('Repeat this transaction automatically'),
              value: _isRecurring,
              onChanged: (v) => setState(() {
                _isRecurring = v;
                if (v) _isInstallment = false;
              }),
              secondary: const Icon(Icons.repeat),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isRecurring) ...[
              DropdownButtonFormField<String>(
                value: _recurringFreq,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: [
                  AppConstants.daily,
                  AppConstants.weekly,
                  AppConstants.monthly,
                  AppConstants.yearly,
                ]
                    .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                            f[0].toUpperCase() + f.substring(1))))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _recurringFreq = v!),
              ),
              const SizedBox(height: 8),
            ],

            // Installment toggle
            if (widget.transaction == null) ...[
              SwitchListTile(
                title: const Text('Installment Payment'),
                subtitle:
                    const Text('Split into multiple payments'),
                value: _isInstallment,
                onChanged: (v) => setState(() {
                  _isInstallment = v;
                  if (v) _isRecurring = false;
                }),
                secondary: const Icon(Icons.splitscreen),
                contentPadding: EdgeInsets.zero,
              ),
              if (_isInstallment) ...[
                Row(
                  children: [
                    const Text('Number of installments: '),
                    Expanded(
                      child: Slider(
                        value: _installmentCount.toDouble(),
                        min: 2,
                        max: 60,
                        divisions: 58,
                        label: _installmentCount.toString(),
                        onChanged: (v) =>
                            setState(() => _installmentCount = v.round()),
                      ),
                    ),
                    Text(_installmentCount.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (_amountCtrl.text.isNotEmpty &&
                    double.tryParse(_amountCtrl.text) != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Per installment: ${(double.parse(_amountCtrl.text) / _installmentCount).toStringAsFixed(2)} $_currency',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                  : Text(isEdit ? 'Update' : 'Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
