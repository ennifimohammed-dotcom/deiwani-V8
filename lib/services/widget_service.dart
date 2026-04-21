import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget service — writes 6 keys to SharedPreferences
/// and triggers native Android widget refresh.
/// Compatible with Flutter 3.22.0 — no external packages.
class WidgetService {
  static const _ch = MethodChannel('com.debttracker.app/widgets');

  static Future<void> update({
    required String balance,
    required String lent,
    required String borrowed,
    required String overdue,
    required String currency,
    required bool positive,
  }) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('flutter.w_balance',  balance);
      await p.setString('flutter.w_lent',     lent);
      await p.setString('flutter.w_borrowed', borrowed);
      await p.setString('flutter.w_overdue',  overdue);
      await p.setString('flutter.w_currency', currency);
      await p.setBool  ('flutter.w_positive', positive);
      await _ch.invokeMethod('refresh');
    } catch (_) {}
  }

  /// Kept for backwards compat with HomeScreen.
  /// Returns empty — widget tap just opens the app.
  static Future<String> getPendingRoute() async => '';

  /// Kept for backwards compat with screens that call recordActivity
  static Future<void> recordActivity(String description) async {
    // no-op — not used by the simplified widget
  }
}
