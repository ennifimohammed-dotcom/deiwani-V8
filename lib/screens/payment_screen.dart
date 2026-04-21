import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';

class PaymentScreen extends StatefulWidget {
  final Debt debt;
  const PaymentScreen({super.key, required this.debt});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  DateTime _payDate  = DateTime.now();
  bool _loading      = false;
  // #9: show confirmed payment immediately
  double? _confirmedAmount;
  String? _confirmedDate;

  String get _lang => context.read<AuthProvider>().lang;
  String tr(String k) => AppTranslations.get(_lang, k);

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('fillRequired'), style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: AppTheme.red,
      ));
      return;
    }
    setState(() => _loading = true);
    final savedDate = _payDate;
    final savedNote = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    try {
      await context.read<DebtProvider>().addPayment(
            widget.debt.id!, amount, savedDate, savedNote);
      if (!mounted) return;
      // #9: Show amount immediately, keep on screen, then pop
      final fmt = DateFormat('dd/MM/yyyy',
          _lang == 'ar' ? 'ar' : _lang == 'fr' ? 'fr' : 'en');
      setState(() {
        _confirmedAmount = amount;
        _confirmedDate   = fmt.format(savedDate);
        _amountCtrl.clear();
        _noteCtrl.clear();
        _payDate = DateTime.now();
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(tr('payAdded'),
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: AppTheme.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _payDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: _lang == 'ar' ? const Locale('ar') : _lang == 'fr' ? const Locale('fr') : const Locale('en'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: context.read<AuthProvider>().themeColor)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _payDate = d);
  }

  @override
  Widget build(BuildContext context) {
    final debt   = widget.debt;
    final isLend = debt.type == 'lend';
    final color  = isLend ? AppTheme.green : AppTheme.red;
    final auth   = context.watch<AuthProvider>();
    final lang   = auth.lang;
    final code   = auth.currencyCode;
    final arabicNum = auth.useArabicNumerals;
    final fmt = DateFormat('dd/MM/yyyy',
        lang == 'ar' ? 'ar' : lang == 'fr' ? 'fr' : 'en');

    return Scaffold(
      body: Column(children: [
        Container(
          decoration: BoxDecoration(gradient: AppTheme.gradientFor(auth.themeColor)),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(tr('payTitle'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.white, fontFamily: 'Tajawal')),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // #9: Confirmed payment banner (shows immediately)
              if (_confirmedAmount != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.green.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('payAdded'),
                          style: const TextStyle(fontWeight: FontWeight.w800,
                              color: AppTheme.green, fontFamily: 'Tajawal', fontSize: 14)),
                      Text(
                        '+ ${CurrencyFormatter.format(_confirmedAmount!, code, lang, useArabicNumerals: arabicNum)}  •  $_confirmedDate',
                        style: const TextStyle(fontSize: 12, color: AppTheme.green, fontFamily: 'Tajawal'),
                      ),
                    ])),
                  ]),
                ),

              // Debt summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCard(false),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12), shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
                      child: Center(child: Text(
                          debt.name.isNotEmpty ? debt.name[0] : '؟',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                              color: color, fontFamily: 'Tajawal'))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(debt.name, style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Tajawal')),
                      Text('${tr('remaining')}: ${CurrencyFormatter.format(debt.remainingAmount, code, lang, useArabicNumerals: arabicNum)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(isLend ? tr('lendBtn') : tr('borrowBtn'),
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Tajawal')),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: debt.progressPercent,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
                  ),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${tr('paid')}: ${CurrencyFormatter.format(debt.paidAmount, code, lang, useArabicNumerals: arabicNum)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('${(debt.progressPercent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // Payment form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCard(false),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('payTitle'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: auth.themeColor, fontFamily: 'Tajawal')),
                  const SizedBox(height: 14),

                  _label(tr('payAmount')),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      suffixText: CurrencyFormatter.symbol(code),
                      suffixStyle: TextStyle(color: auth.themeColor, fontWeight: FontWeight.w700, fontFamily: 'Tajawal'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _label(tr('payDate')),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.bgCard2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(fmt.format(_payDate),
                            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Tajawal')),
                        const Spacer(),
                        Icon(Icons.edit_calendar_outlined, color: auth.themeColor, size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _label(tr('payNote')),
                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      hintText: '...',
                      prefixIcon: const Icon(Icons.notes_outlined),
                      filled: true, fillColor: AppTheme.bgCard2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: auth.themeColor, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(tr('confirmPay'), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ]),
              ),

              // Payment history
              if (debt.payments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard(false),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.history_rounded, color: auth.themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(tr('payHistory'), style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w800, color: auth.themeColor, fontFamily: 'Tajawal')),
                      const Spacer(),
                      Text('${debt.payments.length}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ]),
                    const SizedBox(height: 12),
                    ...debt.payments.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard2, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.green.withOpacity(0.2))),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Center(child: Icon(Icons.payments_outlined, color: AppTheme.green, size: 18)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('+ ${CurrencyFormatter.format(p.amount, code, lang, useArabicNumerals: arabicNum)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                  color: AppTheme.green, fontFamily: 'Tajawal')),
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined, size: 11, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(fmt.format(p.date),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            if (p.note != null) ...[
                              const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                              Expanded(child: Text(p.note!, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
                            ],
                          ]),
                        ])),
                      ]),
                    )),
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

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(color: AppTheme.textSecondary,
        fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Tajawal')),
  );
}
