// lib/core/currency.dart
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

const List<CurrencyInfo> kSupportedCurrencies = [
  CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
  CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
  CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  CurrencyInfo(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
  CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
  CurrencyInfo(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
];
