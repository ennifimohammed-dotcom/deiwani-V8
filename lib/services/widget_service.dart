import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes widget data to SharedPreferences and triggers native Android refresh.
///
/// IMPORTANT — key naming rule (shared_preferences ^2.2.x):
///   The plugin automatically prepends "flutter." to every key before storing.
///   So  setString('widget_net_balance', v)  →  Android key = "flutter.widget_net_balance"
///   Writing 'flutter.widget_net_balance' would create "flutter.flutter.widget_net_balance"
///   which Android widgets can never find.
///   → All Dart keys must be written WITHOUT the "flutter." prefix.
///   → Android Kotlin code reads WITH the "flutter." prefix (correct as-is).
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

      // Legacy keys for BalanceWidget (keys WITHOUT flutter. prefix —
      // plugin adds it automatically → Android reads as "flutter.w_*")
      await p.setString('w_balance',  balance);
      await p.setString('w_lent',     lent);
      await p.setString('w_borrowed', borrowed);
      await p.setString('w_overdue',  overdue);
      await p.setString('w_currency', currency);
      await p.setBool  ('w_positive', positive);

      // New keys for DeiwaniWidget1 and DeiwaniWidget2
      // (keys WITHOUT flutter. prefix — Android reads as "flutter.widget_*")
      await p.setString('widget_net_balance',     balance);
      await p.setString('widget_total_lent',      lent);
      await p.setString('widget_total_borrowed',  borrowed);
      await p.setString('widget_overdue_count',   overdue);
      await p.setString('widget_total_settled',   totalSettled);
      await p.setBool  ('widget_net_positive',    positive);
      await p.setString('widget_currency_symbol', currency);
      await p.setString('widget_currency_code',   currencyCode);
      if (lastActivity.isNotEmpty && lastActivityTs > 0) {
        await p.setString('widget_last_activity',    lastActivity);
        await p.setInt   ('widget_last_activity_ts', lastActivityTs);
      }

      await _ch.invokeMethod('refresh');
    } catch (_) {}
  }

  /// Returns the pending navigation route written by MainActivity on widget tap,
  /// then clears it so it is only consumed once.
  ///
  /// MainActivity writes natively: editor.putString("flutter.widget_pending_route", screen)
  /// Flutter must read WITHOUT the prefix so the plugin resolves to the same key:
  ///   getString('widget_pending_route') → reads "flutter.widget_pending_route" ✓
  static Future<String> getPendingRoute() async {
    try {
      final p = await SharedPreferences.getInstance();
      final route = p.getString('widget_pending_route') ?? '';
      if (route.isNotEmpty) {
        await p.remove('widget_pending_route');
      }
      return route;
    } catch (_) {
      return '';
    }
  }

  /// Kept for backwards compatibility with screens that call recordActivity.
  static Future<void> recordActivity(String description) async {}
}
