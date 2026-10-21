// lib/providers/settings_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/currency.dart';

class SettingsProvider extends ChangeNotifier {
  static const _currencyKey = 'currency_code';
  static const _biometricsKey = 'use_biometrics';

  String _currencyCode = 'INR';
  bool _useBiometrics = false;

  String get currencyCode => _currencyCode;
  bool get useBiometrics => _useBiometrics;

  CurrencyInfo get currency => kSupportedCurrencies.firstWhere(
        (c) => c.code == _currencyCode,
        orElse: () => kSupportedCurrencies.first,
      );

  String get symbol => currency.symbol;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString(_currencyKey) ?? 'INR';
    _useBiometrics = prefs.getBool(_biometricsKey) ?? false;
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
    notifyListeners();
  }

  Future<void> setBiometrics(bool value) async {
    _useBiometrics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsKey, value);
    notifyListeners();
  }
}
