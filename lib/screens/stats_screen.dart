import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DebtProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = auth.lang;
    final code = auth.currencyCode;
    final isDark = auth.isDark;
    String tr(String k) => AppTranslations.get(lang, k);

    final lent = dp.totalLent;
    final borrowed = dp.totalBorrowed;
    final settled = dp.totalSettled;
    final total = lent + borrowed + settled;
    final net = dp.netBalance;

    final settledPct = (dp.settledCount > 0 &&
            (dp.active.length + dp.settledCount) > 0)
        ? (dp.settledCount /
                (dp.active.length + dp.settledCount) *
                100)
            .toDouble()
        : 0.0;

    final top3 = [...dp.active]
      ..sort(
          (a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    final top = top3.take(3).toList();

    return Scaffold(
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(tr('stats'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Tajawal')),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // ── Pie Chart ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard(isDark),
                child: Column(children: [
                  Text(tr('debtDist'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Tajawal',
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.textPrimary)),
                  const SizedBox(height: 20),
                  total == 0
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(tr('noDebts'),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary)))
                      : Row(children: [
                          // Pie — no overlapping titles
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: PieChart(PieChartData(
                              sections: [
                                if (lent > 0)
                                  PieChartSectionData(
                                      color: AppTheme.green,
                                      value: lent,
                                      title: '',
                                      radius: 56),
                                if (borrowed > 0)
                                  PieChartSectionData(
                                      color: AppTheme.red,
                                      value: borrowed,
                                      title: '',
                                      radius: 56),
                                if (settled > 0)
                                  PieChartSectionData(
                                      color: AppTheme.gold,
                                      value: settled,
                                      title: '',
                                      radius: 56),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 32,
                            )),
                          ),
                          const SizedBox(width: 20),
                          // Legends — séparées, aucun chevauchement
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (lent > 0)
                                  _legend(
                                    AppTheme.green,
                                    tr('lent'),
                                    CurrencyFormatter.format(
                                        lent, code, lang,
                                        decimals: 0),
                                    total > 0
                                        ? '${(lent / total * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                  ),
                                if (borrowed > 0)
                                  _legend(
                                    AppTheme.red,
                                    tr('borrowed'),
                                    CurrencyFormatter.format(
                                        borrowed, code, lang,
                                        decimals: 0),
                                    total > 0
                                        ? '${(borrowed / total * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                  ),
                                if (settled > 0)
                                  _legend(
                                    AppTheme.gold,
                                    tr('settled'),
                                    CurrencyFormatter.format(
                                        settled, code, lang,
                                        decimals: 0),
                                    total > 0
                                        ? '${(settled / total * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                  ),
                              ],
                            ),
                          ),
                        ]),
                ]),
              ),
              const SizedBox(height: 14),

              // ── 4 Stat Cards ──
              Row(children: [
                Expanded(
                    child: _statCard(
                        tr('netBalStat'),
                        CurrencyFormatter.format(net, code, lang,
                            decimals: 0),
                        Icons.account_balance_wallet_rounded,
                        net >= 0 ? AppTheme.green : AppTheme.red,
                        isDark)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statCard(
                        tr('settledRecords'),
                        '${settledPct.toStringAsFixed(0)}%',
                        Icons.check_circle_outline_rounded,
                        AppTheme.gold,
                        isDark)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _statCard(
                        tr('totalRecords'),
                        '${dp.active.length + dp.settledCount}',
                        Icons.list_alt_rounded,
                        AppTheme.primary,
                        isDark)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statCard(
                        tr('overdue'),
                        '${dp.overdueCount}',
                        Icons.warning_amber_rounded,
                        dp.overdueCount > 0
                            ? AppTheme.red
                            : AppTheme.textSecondary,
                        isDark)),
              ]),

              // ── Top 3 ──
              if (top.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.glassCard(isDark),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('top3'),
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Tajawal',
                                color: isDark
                                    ? AppTheme.darkText
                                    : AppTheme.textPrimary)),
                        const SizedBox(height: 14),
                        ...top.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final d = e.value;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  gradient: rank == 1
                                      ? AppTheme.goldGradient
                                      : null,
                                  color: rank != 1
                                      ? (isDark
                                          ? AppTheme.darkCard2
                                          : AppTheme.bgCard2)
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('$rank',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: rank == 1
                                              ? Colors.white
                                              : AppTheme.textSecondary)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(d.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Tajawal',
                                          color: isDark
                                              ? AppTheme.darkText
                                              : AppTheme.textPrimary))),
                              Text(
                                  CurrencyFormatter.format(
                                      d.remainingAmount, code, lang,
                                      decimals: 0),
                                  style: TextStyle(
                                      color: d.type == 'lend'
                                          ? AppTheme.green
                                          : AppTheme.red,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Tajawal')),
                            ]),
                          );
                        }),
                      ]),
                ),
              ],
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _legend(
      Color color, String label, String val, String pct) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 12, height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Tajawal')),
                  Text('$val · $pct',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                ]),
          ),
        ]),
      );

  Widget _statCard(String label, String val, IconData icon,
      Color color, bool isDark) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassCard(isDark),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 10),
              Text(val,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamily: 'Tajawal')),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary)),
            ]),
      );
}
