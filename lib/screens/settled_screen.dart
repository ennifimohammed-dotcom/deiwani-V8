import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';
import 'debt_detail_screen.dart';

class SettledScreen extends StatelessWidget {
  const SettledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DebtProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = auth.lang;
    final code = auth.currencyCode;
    final list = dp.settled;
    final fmt = DateFormat('dd/MM/yyyy',
        lang == 'ar' ? 'ar' : lang == 'fr' ? 'fr' : 'en');
    String tr(String k) => AppTranslations.get(lang, k);

    return Scaffold(
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B6B45), Color(0xFF28A865)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(tr('settled'),
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
                    child: Text('✓ ${list.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 10),
                // Total settled banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('settledTotal'),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12,
                                  fontFamily: 'Tajawal')),
                          Text(
                              CurrencyFormatter.format(
                                  dp.totalSettled, code, lang),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Tajawal')),
                        ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 64, color: AppTheme.border),
                        const SizedBox(height: 12),
                        Text(tr('noSettled'),
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15)),
                      ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final d = list[i];
                    final isLend = d.type == 'lend';
                    // ── Tapping opens DebtDetailScreen with full info ──
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  DebtDetailScreen(debt: d))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.green.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.green.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.green.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.green.withOpacity(0.3)),
                            ),
                            child: const Center(
                              child: Icon(Icons.check_rounded,
                                  color: AppTheme.green, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(d.name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Tajawal')),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 11,
                                        color: AppTheme.textSecondary),
                                    const SizedBox(width: 3),
                                    Text(d.phone,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary)),
                                  ]),
                                  Text(
                                      '${tr('createdAt')}: ${fmt.format(d.createdAt)}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary)),
                                  // Show payment count
                                  if (d.payments.isNotEmpty)
                                    Text(
                                        '${d.payments.length} ${lang == 'ar' ? 'دفعة' : lang == 'fr' ? 'paiement(s)' : 'payment(s)'}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.green)),
                                ]),
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    CurrencyFormatter.format(
                                        d.amount, code, lang),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.green,
                                        fontFamily: 'Tajawal')),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                      isLend
                                          ? tr('lendBtn')
                                          : tr('borrowBtn'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.green,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Tajawal')),
                                ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 11,
                                      color: AppTheme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                      lang == 'ar'
                                          ? 'تفاصيل'
                                          : lang == 'fr'
                                              ? 'Détails'
                                              : 'Details',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary)),
                                ]),
                              ]),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
