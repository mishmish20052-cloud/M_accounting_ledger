// lib/services/ai_service.dart
// Placeholder for future AI integration (e.g., smart categorization)

class AiService {
  /// Suggest a category based on a transaction description.
  static Future<String?> suggestCategory(String description) async {
    // Simple keyword-based heuristic; can be replaced with a real ML model.
    final desc = description.toLowerCase();
    if (desc.contains('salary') || desc.contains('payroll')) return 'Salary';
    if (desc.contains('groceries') || desc.contains('supermarket') || desc.contains('food')) {
      return 'Food & Dining';
    }
    if (desc.contains('uber') || desc.contains('taxi') || desc.contains('fuel') ||
        desc.contains('petrol')) {
      return 'Transport';
    }
    if (desc.contains('rent') || desc.contains('mortgage')) return 'Rent';
    if (desc.contains('electric') || desc.contains('water') || desc.contains('internet')) {
      return 'Utilities';
    }
    if (desc.contains('hospital') || desc.contains('pharmacy') || desc.contains('doctor')) {
      return 'Health';
    }
    if (desc.contains('netflix') || desc.contains('spotify') || desc.contains('cinema')) {
      return 'Entertainment';
    }
    if (desc.contains('amazon') || desc.contains('shopping')) return 'Shopping';
    return null;
  }

  /// Parse a natural-language transaction description and extract fields.
  static Map<String, dynamic> parseTransactionText(String text) {
    final result = <String, dynamic>{};
    // Try to extract amount
    final amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      result['amount'] = double.tryParse(amountMatch.group(1) ?? '');
    }
    // Try to determine type
    final lower = text.toLowerCase();
    if (lower.contains('received') || lower.contains('income') || lower.contains('salary')) {
      result['type'] = 'income';
    } else if (lower.contains('paid') || lower.contains('spent') || lower.contains('bought')) {
      result['type'] = 'expense';
    }
    return result;
  }
}
