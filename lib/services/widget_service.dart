import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes widget data to SharedPreferences and triggers native Android refresh.
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
    String currencyCode = 'MAD',
    String lastActivity = '',
    int lastActivityTs = 0,
    String totalSettled = '0',
  }) async {
    try {
      final p = await SharedPreferences.getInstance();

      // Legacy keys — kept for BalanceWidget backward compatibility
      await p.setString('flutter.w_balance',  balance);
      await p.setString('flutter.w_lent',     lent);
      await p.setString('flutter.w_borrowed', borrowed);
      await p.setString('flutter.w_overdue',  overdue);
      await p.setString('flutter.w_currency', currency);
      await p.setBool  ('flutter.w_positive', positive);

      // New keys for DeiwaniWidget1 and DeiwaniWidget2
      await p.setString('flutter.widget_net_balance',     balance);
      await p.setString('flutter.widget_total_lent',      lent);
      await p.setString('flutter.widget_total_borrowed',  borrowed);
      await p.setString('flutter.widget_overdue_count',   overdue);
      await p.setString('flutter.widget_total_settled',   totalSettled);
      await p.setBool  ('flutter.widget_net_positive',    positive);
      await p.setString('flutter.widget_currency_symbol', currency);
      await p.setString('flutter.widget_currency_code',   currencyCode);
      if (lastActivity.isNotEmpty && lastActivityTs > 0) {
        await p.setString('flutter.widget_last_activity',    lastActivity);
        await p.setInt   ('flutter.widget_last_activity_ts', lastActivityTs);
      }

      await _ch.invokeMethod('refresh');
    } catch (_) {}
  }

  /// Returns the pending navigation route set by a widget tap, then clears it.
  static Future<String> getPendingRoute() async {
    try {
      final p = await SharedPreferences.getInstance();
      final route = p.getString('flutter.widget_pending_route') ?? '';
      if (route.isNotEmpty) {
        await p.remove('flutter.widget_pending_route');
      }
      return route;
    } catch (_) {
      return '';
    }
  }

  /// Kept for backwards compatibility with screens that call recordActivity.
  static Future<void> recordActivity(String description) async {}
}
