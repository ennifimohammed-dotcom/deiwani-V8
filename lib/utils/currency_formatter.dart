/// ديوني CurrencyFormatter v2
/// - USD ($) and EUR (€): symbol on RIGHT
/// - All others: symbol on LEFT
/// - Arabic numerals option
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
    int decimals = 2, bool useArabicNumerals = false,
  }) {
    final sym = symbol(currencyCode);
    final num = formatNumber(amount, decimals, useArabicNumerals: useArabicNumerals);
    return isRightSymbol(currencyCode) ? '$num $sym' : '$sym $num';
  }

  static String formatNumber(double value, int decimals, {bool useArabicNumerals = false}) {
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
    final result = '$negative$buf.$decPart';
    return useArabicNumerals ? _toArabic(result) : result;
  }

  static String _toArabic(String s) {
    const l = ['0','1','2','3','4','5','6','7','8','9'];
    const a = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    var r = s;
    for (var i = 0; i < l.length; i++) r = r.replaceAll(l[i], a[i]);
    return r;
  }
}
