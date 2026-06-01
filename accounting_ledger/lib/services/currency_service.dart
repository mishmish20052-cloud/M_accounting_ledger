// lib/services/currency_service.dart
import '../models/currency.dart';

class CurrencyService {
  static final Map<String, double> _rates = {
    for (final c in Currency.defaultCurrencies) c.code: c.rateToUsd,
  };

  static List<Currency> get availableCurrencies => Currency.defaultCurrencies;

  static Currency getCurrency(String code) {
    return Currency.defaultCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.defaultCurrencies.first,
    );
  }

  /// Convert [amount] from [fromCode] to [toCode]
  static double convert(double amount, String fromCode, String toCode) {
    if (fromCode == toCode) return amount;
    final fromRate = _rates[fromCode] ?? 1.0;
    final toRate = _rates[toCode] ?? 1.0;
    // Convert to USD first, then to target
    final inUsd = amount / fromRate;
    return inUsd * toRate;
  }

  static void updateRates(Map<String, double> newRates) {
    _rates.addAll(newRates);
  }
}
