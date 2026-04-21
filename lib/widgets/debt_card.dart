import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/debt.dart';
import '../providers/auth_provider.dart';
import '../providers/debt_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';
import '../screens/debt_detail_screen.dart';
import '../screens/payment_screen.dart';

class DebtCard extends StatelessWidget {
  final Debt debt;
  final bool showDetails;

  const DebtCard({super.key, required this.debt, this.showDetails = false});

  String _tr(BuildContext ctx, String k) =>
      AppTranslations.get(ctx.read<AuthProvider>().lang, k);

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: debt.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _settleDebt(BuildContext context) {
    final tr = (String k) => _tr(context, k);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(tr('settleTitle'),
            style: const TextStyle(fontFamily: 'Tajawal')),
        content: Text(tr('settleMsg'),
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'),
                  style: const TextStyle(fontFamily: 'Tajawal'))),
          TextButton(
            onPressed: () async {
              await context.read<DebtProvider>().settleDebt(debt);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(tr('confirm'),
                style: const TextStyle(
                    color: AppTheme.green, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _deleteDebt(BuildContext context) {
    final tr = (String k) => _tr(context, k);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(tr('deleteTitle'),
            style: const TextStyle(fontFamily: 'Tajawal')),
        content: Text(tr('deleteMsg'),
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'),
                  style: const TextStyle(fontFamily: 'Tajawal'))),
          TextButton(
            onPressed: () async {
              await context.read<DebtProvider>().deleteDebt(debt.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(tr('confirm'),
                style: const TextStyle(
                    color: AppTheme.red, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLend = debt.type == 'lend';
    final color = isLend ? AppTheme.green : AppTheme.red;
    final auth = context.watch<AuthProvider>();
    final lang = auth.lang;
    final code = auth.currencyCode;
    String tr(String k) => AppTranslations.get(lang, k);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: debt.isOverdue
                ? AppTheme.red.withOpacity(0.4)
                : AppTheme.border,
          ),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          // ── Top Row ──
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                    debt.name.isNotEmpty ? debt.name[0] : '؟',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFamily: 'Tajawal')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(debt.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                fontFamily: 'Tajawal')),
                      ),
                      if (debt.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppTheme.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(tr('overdueTag'),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.red,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.phone_outlined,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(debt.phone,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                    ]),
                    if (debt.progressPercent > 0 &&
                        debt.progressPercent < 1.0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: debt.progressPercent,
                          backgroundColor: AppTheme.border,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ]),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                  CurrencyFormatter.format(
                      debt.remainingAmount, code, lang, decimals: 0),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamily: 'Tajawal')),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7)),
                child: Text(isLend ? tr('lendBtn') : tr('borrowBtn'),
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Tajawal')),
              ),
            ]),
          ]),

          // ── Extra details ──
          if (showDetails && debt.payments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.bgCard2,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                _detail(tr('total'),
                    CurrencyFormatter.format(debt.amount, code, lang,
                        decimals: 0)),
                _detail(tr('paid'),
                    CurrencyFormatter.format(debt.paidAmount, code, lang,
                        decimals: 0),
                    color: AppTheme.green),
                _detail(tr('remaining'),
                    CurrencyFormatter.format(
                        debt.remainingAmount, code, lang, decimals: 0),
                    color: AppTheme.red),
              ]),
            ),
          ],

          // ── Action Buttons ──
          const SizedBox(height: 8),
          Row(children: [
            _actionBtn(tr('call'), AppTheme.green, () => _call(context)),
            const SizedBox(width: 5),
            _actionBtn(tr('payment'), AppTheme.primary, () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PaymentScreen(debt: debt)))),
            const SizedBox(width: 5),
            _actionBtn(tr('settle'), AppTheme.gold, () => _settleDebt(context)),
            const SizedBox(width: 5),
            _actionBtn(tr('delete'), AppTheme.red, () => _deleteDebt(context)),
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Tajawal')),
          ),
        ),
      );

  Widget _detail(String label, String val, {Color? color}) =>
      Expanded(
        child: Column(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(val,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppTheme.textPrimary,
                  fontFamily: 'Tajawal'),
              overflow: TextOverflow.ellipsis),
        ]),
      );
}
