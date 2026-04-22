/// ديوني CurrencyFormatter v3
/// - USD ($) and EUR (€): symbol on RIGHT
/// - All others: symbol on LEFT
/// - Always Latin numerals (0-9) — Arabic numeral option removed
class CurrencyFormatter {
  static const Map<String, String> _symbols = {
    'MAD': 'د.م', 'DZD': 'د.ج', 'TND': 'د.ت',
    'SAR': 'ر.س', 'EGP': 'ج.م', 'EUR': '€', 'USD': '\$',
  };
  static const Set<String> _rightSide = {'EUR', 'USD'};

  static String symbol(String code) => _symbols[code] ?? code;
  static bool isRightSymbol(String code) => _rightSide.contains(code);

  static String format(
    double amount, String currencyCode, String lang, {
    int decimals = 2,
    // useArabicNumerals kept for API compatibility — always ignored
    bool useArabicNumerals = false,
  }) {
    final sym = symbol(currencyCode);
    final num = formatNumber(amount, decimals);
    return isRightSymbol(currencyCode) ? '$num $sym' : '$sym $num';
  }

  static String formatNumber(double value, int decimals, {
    // useArabicNumerals kept for API compatibility — always ignored
    bool useArabicNumerals = false,
  }) {
    final abs = value.abs();
    final negative = value < 0 ? '-' : '';
    final raw = abs.toStringAsFixed(decimals);
    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$negative$buf.$decPart';
  }
}
