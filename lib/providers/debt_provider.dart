import 'package:flutter/foundation.dart';
import '../models/debt.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../utils/currency_formatter.dart';

class DebtProvider extends ChangeNotifier {
  List<Debt> _all     = [];
  String _search      = '';
  String _curSymbol   = 'DH';

  // ── Getters ──
  List<Debt> get active   => _sorted().where((d) => !d.isSettled).toList();
  List<Debt> get lent     => active.where((d) => d.type == 'lend').toList();
  List<Debt> get borrowed => active.where((d) => d.type == 'borrow').toList();
  List<Debt> get settled  => _all.where((d) => d.isSettled).toList();
  List<Debt> get overdue  => active.where((d) => d.isOverdue).toList();
  List<Debt> get allDebts => _all;

  double get totalLent     => lent.fold(0.0, (s, d) => s + d.remainingAmount);
  double get totalBorrowed => borrowed.fold(0.0, (s, d) => s + d.remainingAmount);
  double get netBalance    => totalLent - totalBorrowed;
  double get totalSettled  => settled.fold(0.0, (s, d) => s + d.amount);

  int get lentCount     => lent.length;
  int get borrowedCount => borrowed.length;
  int get overdueCount  => overdue.length;
  int get settledCount  => settled.length;

  List<Debt> _sorted() {
    var list = List<Debt>.from(_all);
    if (_search.isNotEmpty) {
      list = list.where((d) =>
          d.name.contains(_search) || d.phone.contains(_search)).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Store currency info for widget
  String _curCode = 'MAD';
  
  void syncPrefs({
    required String curSymbol,
    required String curCode,
    required String lang,
    required bool   isDark,
    required bool   arabicNums,
  }) {
    _curSymbol = curSymbol;
    _curCode   = curCode;
  }

  Future<void> load() async {
    _all = await DatabaseService().getAllDebts();
    notifyListeners();
    _pushWidgets();
  }

  Future<void> addDebt(Debt debt) async {
    await DatabaseService().insertDebt(debt);
    await load();
  }

  Future<void> updateDebt(Debt debt) async {
    await DatabaseService().updateDebt(debt);
    await load();
  }

  Future<void> deleteDebt(int id) async {
    await DatabaseService().deleteDebt(id);
    await load();
  }

  Future<void> settleDebt(Debt debt) async {
    final remaining = debt.remainingAmount;
    if (remaining > 0) {
      await DatabaseService()
          .addPayment(debt.id!, remaining, DateTime.now(), null);
    }
    await DatabaseService().updateDebt(debt.copyWith(isSettled: true));
    await load();
  }

  Future<void> addPayment(
      int debtId, double amount, DateTime date, String? note) async {
    await DatabaseService().addPayment(debtId, amount, date, note);
    final d = _all.firstWhere(
      (x) => x.id == debtId,
      orElse: () => throw Exception('Debt $debtId not found'),
    );
    if (d.paidAmount + amount >= d.amount) {
      await DatabaseService().updateDebt(d.copyWith(isSettled: true));
    }
    await load();
  }

  Future<void> deleteAll() async {
    await DatabaseService().deleteAll();
    await load();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  // ── Push data to widgets (6 keys only) ──
  void _pushWidgets() {
    // Use CurrencyFormatter.symbol() for proper Arabic display (د.م instead of DH)
    final displaySymbol = CurrencyFormatter.symbol(_curCode);
    WidgetService.update(
      balance:  _fmt(netBalance),
      lent:     _fmt(totalLent,     dec: 0),
      borrowed: _fmt(totalBorrowed, dec: 0),
      overdue:  '$overdueCount',
      currency: displaySymbol,
      positive: netBalance >= 0,
    );
  }

  String _fmt(double v, {int dec = 2}) {
    final abs = v.abs();
    final neg = v < 0 ? '-' : '';
    final raw = abs.toStringAsFixed(dec);
    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = dec > 0 ? '.${parts.length > 1 ? parts[1] : '00'}' : '';
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$neg$buf$decPart';
  }
}
