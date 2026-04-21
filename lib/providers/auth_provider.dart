import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _authenticated = false;
  bool _hasPin = false;
  bool _lockEnabled = true;
  String _lang = 'ar';
  String _currencyCode = 'MAD';
  String _currencyName = 'الدرهم المغربي';
  String _currencySymbol = 'DH';
  ThemeMode _themeMode = ThemeMode.light;
  Color _themeColor = const Color(0xFF2A3F7E);
  bool _useArabicNumerals = false;

  bool get authenticated => _authenticated;
  bool get hasPin => _hasPin;
  bool get lockEnabled => _lockEnabled;
  String get lang => _lang;
  String get currencyCode => _currencyCode;
  String get currencyName => _currencyName;
  String get currencySymbol => _currencySymbol;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  String get displayCurrency => _currencyName;
  Color get themeColor => _themeColor;
  bool get useArabicNumerals => _useArabicNumerals;

  // 7 preset theme colors
  static const List<Color> themeColors = [
    Color(0xFF2A3F7E), // Blue (default)
    Color(0xFF1B6B45), // Green
    Color(0xFF7B2D8B), // Purple
    Color(0xFFC0392B), // Red
    Color(0xFFD35400), // Orange
    Color(0xFF1A5276), // Teal
    Color(0xFF2C3E50), // Dark Slate
  ];

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _hasPin = p.getString('pin_v4') != null;
    _lockEnabled = p.getBool('lock_v4') ?? true;
    _lang = p.getString('lang_v4') ?? 'ar';
    _currencyCode = p.getString('cur_code_v4') ?? 'MAD';
    _currencyName = p.getString('cur_name_v4') ?? 'الدرهم المغربي';
    _currencySymbol = p.getString('cur_sym_v4') ?? 'DH';
    final tmStr = p.getString('theme_mode') ?? 'light';
    _themeMode = tmStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
    final colorVal = p.getInt('theme_color') ?? 0xFF2A3F7E;
    _themeColor = Color(colorVal);
    _useArabicNumerals = p.getBool('arabic_numerals') ?? false;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('pin_v4', pin);
    _hasPin = true;
    _authenticated = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString('pin_v4');
    if (stored == pin) { _authenticated = true; notifyListeners(); return true; }
    return false;
  }

  Future<void> setLockEnabled(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('lock_v4', val);
    _lockEnabled = val;
    if (!val) _authenticated = true;
    notifyListeners();
  }

  Future<void> setLanguage(String l) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lang_v4', l);
    _lang = l;
    notifyListeners();
  }

  Future<void> setCurrency(String code, String name, String symbol) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cur_code_v4', code);
    await p.setString('cur_name_v4', name);
    await p.setString('cur_sym_v4', symbol);
    _currencyCode = code;
    _currencyName = name;
    _currencySymbol = symbol;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('theme_color', color.value);
    _themeColor = color;
    notifyListeners();
  }

  Future<void> setArabicNumerals(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('arabic_numerals', val);
    _useArabicNumerals = val;
    notifyListeners();
  }

  void skipAuth() { _authenticated = true; notifyListeners(); }
}
