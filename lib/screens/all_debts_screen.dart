import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../models/debt.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';
import '../widgets/debt_card.dart';

class AllDebtsScreen extends StatefulWidget {
  const AllDebtsScreen({super.key});
  @override
  State<AllDebtsScreen> createState() => _AllDebtsScreenState();
}

class _AllDebtsScreenState extends State<AllDebtsScreen> {
  int _filter = 0;

  String get _lang => context.read<AuthProvider>().lang;
  String tr(String k) => AppTranslations.get(_lang, k);

  List<Debt> _filtered(DebtProvider dp) {
    switch (_filter) {
      case 1: return dp.lent;
      case 2: return dp.borrowed;
      case 3: return dp.overdue;
      default: return dp.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DebtProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = auth.lang;
    final code = auth.currencyCode;
    final list = _filtered(dp);

    return Scaffold(
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                        AppTranslations.get(lang, 'allDebts'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Tajawal')),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${list.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              // Summary chips with CurrencyFormatter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(children: [
                  _chip(AppTranslations.get(lang, 'lent'),
                      CurrencyFormatter.format(
                          dp.totalLent, code, lang, decimals: 0),
                      AppTheme.green),
                  const SizedBox(width: 8),
                  _chip(AppTranslations.get(lang, 'borrowed'),
                      CurrencyFormatter.format(
                          dp.totalBorrowed, code, lang, decimals: 0),
                      AppTheme.red),
                  const SizedBox(width: 8),
                  _chip(AppTranslations.get(lang, 'netBalance'),
                      CurrencyFormatter.format(
                          dp.netBalance, code, lang, decimals: 0),
                      AppTheme.gold),
                ]),
              ),
            ]),
          ),
        ),

        // Filter chips
        Container(
          color: AppTheme.bgCard,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip(
                  0,
                  '${AppTranslations.get(lang, 'allFilter')} (${dp.active.length})'),
              _filterChip(
                  1,
                  '↑ ${AppTranslations.get(lang, 'lentFilter')} (${dp.lentCount})'),
              _filterChip(
                  2,
                  '↓ ${AppTranslations.get(lang, 'borrowedFilter')} (${dp.borrowedCount})'),
              _filterChip(
                  3,
                  '⚠️ ${AppTranslations.get(lang, 'overdueFilter')} (${dp.overdueCount})'),
            ]),
          ),
        ),
        Container(height: 1, color: AppTheme.border),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_rounded,
                            size: 64, color: AppTheme.border),
                        const SizedBox(height: 12),
                        Text(
                            AppTranslations.get(
                                lang, 'noDebts'),
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15)),
                      ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      DebtCard(debt: list[i], showDetails: true),
                ),
        ),
      ]),
    );
  }

  Widget _chip(String label, String val, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tajawal')),
            const SizedBox(height: 2),
            Text(val,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal'),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _filterChip(int idx, String label) =>
      GestureDetector(
        onTap: () => setState(() => _filter = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _filter == idx
                ? AppTheme.primary
                : AppTheme.bgCard2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _filter == idx
                    ? AppTheme.primary
                    : AppTheme.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                  color: _filter == idx
                      ? Colors.white
                      : AppTheme.textSecondary)),
        ),
      );
}
