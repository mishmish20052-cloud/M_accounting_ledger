// lib/utils/constants.dart

class AppConstants {
  // DB
  static const String dbName = 'accounting_ledger.db';
  static const int dbVersion = 1;

  // Secure storage keys
  static const String pinKey = 'app_pin';
  static const String biometricKey = 'biometric_enabled';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Tables
  static const String accountsTable = 'accounts';
  static const String transactionsTable = 'transactions';
  static const String installmentsTable = 'installments';
  static const String currenciesTable = 'currencies';
  static const String categoriesTable = 'categories';

  // Transaction types
  static const String income = 'income';
  static const String expense = 'expense';
  static const String transfer = 'transfer';

  // Account types
  static const String bank = 'bank';
  static const String cash = 'cash';
  static const String creditCard = 'creditCard';
  static const String loan = 'loan';
  static const String investment = 'investment';

  // Frequencies
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';

  // Default currency
  static const String defaultCurrency = 'USD';

  // PIN length
  static const int pinLength = 6;

  // Notification IDs
  static const int recurringNotificationId = 1000;
  static const int installmentNotificationId = 2000;

  // Default categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transport',
    'Shopping',
    'Health',
    'Education',
    'Entertainment',
    'Utilities',
    'Rent',
    'Insurance',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Rental Income',
    'Gift',
    'Bonus',
    'Other',
  ];
}
