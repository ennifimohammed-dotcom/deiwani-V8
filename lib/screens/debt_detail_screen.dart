import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';
import 'add_debt_screen.dart';
import 'payment_screen.dart';

class DebtDetailScreen extends StatelessWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});

  String _tr(BuildContext ctx, String k) =>
      AppTranslations.get(ctx.read<AuthProvider>().lang, k);

  Future<void> _call(BuildContext ctx) async {
    final uri = Uri(scheme: 'tel', path: debt.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isLend = debt.type == 'lend';
    final color = isLend ? AppTheme.green : AppTheme.red;
    final auth = context.watch<AuthProvider>();
    final lang = auth.lang;
    final code = auth.currencyCode;
    final fmt = DateFormat('dd/MM/yyyy',
        lang == 'ar' ? 'ar' : lang == 'fr' ? 'fr' : 'en');
    String tr(String k) => _tr(context, k);

    return Scaffold(
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(tr('debtDetails'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Tajawal')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => AddDebtScreen(debt: debt))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                    onPressed: () => _confirmDelete(context),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Text(
                          debt.name.isNotEmpty ? debt.name[0] : '؟',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Tajawal')),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(debt.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Tajawal')),
                          const SizedBox(height: 4),
                          // ── ONE phone icon only ──
                          GestureDetector(
                            onTap: () => _call(context),
                            child: Row(children: [
                              const Icon(Icons.phone_outlined,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 5),
                              Text(debt.phone,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      decoration:
                                          TextDecoration.underline,
                                      fontFamily: 'Tajawal')),
                            ]),
                          ),
                        ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                        isLend ? tr('lendBtn') : tr('borrowBtn'),
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFamily: 'Tajawal')),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Amounts card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.glassCard(false),
                child: Column(children: [
                  _row(tr('total'),
                      CurrencyFormatter.format(debt.amount, code, lang)),
                  _div(),
                  _row(tr('paid'),
                      CurrencyFormatter.format(debt.paidAmount, code, lang),
                      color: AppTheme.green),
                  _div(),
                  _row(tr('remaining'),
                      CurrencyFormatter.format(
                          debt.remainingAmount, code, lang),
                      color: AppTheme.red, bold: true),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: debt.progressPercent,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      '${(debt.progressPercent * 100).toStringAsFixed(0)}% ${tr('paid').toLowerCase()}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 12),

              // Details card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.glassCard(false),
                child: Column(children: [
                  _row(tr('createdAt'), fmt.format(debt.createdAt)),
                  if (debt.dueDate != null) ...[
                    _div(),
                    _row(tr('dueAt'), fmt.format(debt.dueDate!),
                        color: debt.isOverdue ? AppTheme.red : null),
                  ],
                  if (debt.note != null) ...[_div(), _row(tr('note'), debt.note!)],
                  _div(),
                  _row(tr('status'),
                      debt.isSettled ? tr('settledStatus') : tr('pendingStatus'),
                      color: debt.isSettled ? AppTheme.green : AppTheme.gold),
                ]),
              ),

              // Payment history
              if (debt.payments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard(false),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.history_rounded,
                              color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(tr('payHistory'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  fontFamily: 'Tajawal')),
                        ]),
                        const SizedBox(height: 12),
                        ...debt.payments.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: AppTheme.green, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                    '+ ${CurrencyFormatter.format(p.amount, code, lang)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.green,
                                        fontFamily: 'Tajawal')),
                                const Spacer(),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(fmt.format(p.date),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary)),
                                      if (p.note != null)
                                        Text(p.note!,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary)),
                                    ]),
                              ]),
                            )),
                      ]),
                ),
              ],

              if (!debt.isSettled) ...[
                const SizedBox(height: 18),
                // Call button — single, no duplicate
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _call(context),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: Text(tr('call'),
                        style: const TextStyle(fontFamily: 'Tajawal')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => PaymentScreen(debt: debt))),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(tr('partialPay'),
                          style: const TextStyle(fontFamily: 'Tajawal')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _settle(context),
                      icon:
                          const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(tr('fullSettle'),
                          style: const TextStyle(fontFamily: 'Tajawal')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _row(String l, String v, {Color? color, bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        Text(v,
            style: TextStyle(
                color: color ?? AppTheme.textPrimary,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 17 : 13,
                fontFamily: 'Tajawal')),
      ]);

  Widget _div() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: AppTheme.border, height: 1),
      );

  void _confirmDelete(BuildContext context) {
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
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(tr('confirm'),
                style: const TextStyle(
                    color: AppTheme.red, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _settle(BuildContext context) {
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
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(tr('confirm'),
                style: const TextStyle(
                    color: AppTheme.green, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }
}
