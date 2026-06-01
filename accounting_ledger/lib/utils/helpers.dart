// lib/utils/helpers.dart
import 'package:intl/intl.dart';

class Helpers {
  static String formatCurrency(double amount, String currencyCode) {
    try {
      final format = NumberFormat.currency(
        locale: _localeForCurrency(currencyCode),
        symbol: _symbolForCurrency(currencyCode),
        decimalDigits: 2,
      );
      return format.format(amount);
    } catch (_) {
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }
  }

  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String _localeForCurrency(String code) {
    const map = {
      'USD': 'en_US',
      'EUR': 'de_DE',
      'GBP': 'en_GB',
      'SAR': 'ar_SA',
      'AED': 'ar_AE',
      'EGP': 'ar_EG',
      'KWD': 'ar_KW',
      'QAR': 'ar_QA',
    };
    return map[code] ?? 'en_US';
  }

  static String _symbolForCurrency(String code) {
    const map = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'SAR': 'ر.س',
      'AED': 'د.إ',
      'EGP': 'ج.م',
      'KWD': 'د.ك',
      'QAR': 'ر.ق',
      'JOD': 'د.أ',
      'BHD': 'د.ب',
      'OMR': 'ر.ع',
      'LBP': 'ل.ل',
      'TRY': '₺',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
    };
    return map[code] ?? code;
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  static DateTime startOfYear(DateTime date) => DateTime(date.year, 1, 1);

  static DateTime endOfYear(DateTime date) =>
      DateTime(date.year, 12, 31, 23, 59, 59);

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
