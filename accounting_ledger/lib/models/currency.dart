// lib/models/currency.dart

class Currency {
  final String code;
  final String name;
  final String symbol;
  final double rateToUsd;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.rateToUsd = 1.0,
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'rate_to_usd': rateToUsd,
      };

  factory Currency.fromMap(Map<String, dynamic> map) => Currency(
        code: map['code'] as String,
        name: map['name'] as String,
        symbol: map['symbol'] as String,
        rateToUsd: (map['rate_to_usd'] as num?)?.toDouble() ?? 1.0,
      );

  static const List<Currency> defaultCurrencies = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$', rateToUsd: 1.0),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', rateToUsd: 0.92),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', rateToUsd: 0.79),
    Currency(code: 'SAR', name: 'Saudi Riyal', symbol: 'ر.س', rateToUsd: 3.75),
    Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', rateToUsd: 3.67),
    Currency(code: 'EGP', name: 'Egyptian Pound', symbol: 'ج.م', rateToUsd: 30.9),
    Currency(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'د.ك', rateToUsd: 0.31),
    Currency(code: 'QAR', name: 'Qatari Riyal', symbol: 'ر.ق', rateToUsd: 3.64),
    Currency(code: 'JOD', name: 'Jordanian Dinar', symbol: 'د.أ', rateToUsd: 0.71),
    Currency(code: 'BHD', name: 'Bahraini Dinar', symbol: 'د.ب', rateToUsd: 0.38),
    Currency(code: 'OMR', name: 'Omani Rial', symbol: 'ر.ع', rateToUsd: 0.38),
    Currency(code: 'TRY', name: 'Turkish Lira', symbol: '₺', rateToUsd: 32.0),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', rateToUsd: 83.0),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', rateToUsd: 149.0),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', rateToUsd: 7.24),
  ];
}
