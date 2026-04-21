import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debt;
  const AddDebtScreen({super.key, this.debt});
  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _form = GlobalKey<FormState>();
  final _name   = TextEditingController();
  final _phone  = TextEditingController();
  final _amount = TextEditingController();
  final _note   = TextEditingController();
  String   _type = 'lend';
  DateTime? _dueDate;
  DateTime  _createdAt = DateTime.now(); // ← #8: editable creation date
  bool _loading = false;

  String get _lang => context.read<AuthProvider>().lang;
  String tr(String k) => AppTranslations.get(_lang, k);

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      final d = widget.debt!;
      _name.text   = d.name;
      _phone.text  = d.phone;
      _amount.text = d.amount.toStringAsFixed(2);
      _note.text   = d.note ?? '';
      _type        = d.type;
      _dueDate     = d.dueDate;
      _createdAt   = d.createdAt; // load existing
    }
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _amount.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dp = context.read<DebtProvider>();
      final debt = Debt(
        id: widget.debt?.id,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        amount: double.parse(_amount.text.replaceAll(',', '.')),
        type: _type,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: _createdAt, // ← use editable date
        dueDate: _dueDate,
        isSettled: widget.debt?.isSettled ?? false,
        payments: widget.debt?.payments ?? [],
      );
      if (widget.debt == null) { await dp.addDebt(debt); }
      else { await dp.updateDebt(debt); }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(widget.debt == null ? tr('debtAdded') : tr('debtUpdated'),
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: AppTheme.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e', style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: AppTheme.red,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.debt != null;
    final auth = context.watch<AuthProvider>();
    final code = auth.currencyCode;
    final lang = auth.lang;

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
                Text(isEdit ? tr('editDebt') : tr('addNew'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.white, fontFamily: 'Tajawal')),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Type toggle
                Container(
                  decoration: BoxDecoration(
                      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border)),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    _typeBtn('lend',   tr('lendBtn'),   Icons.arrow_upward_rounded,   AppTheme.green),
                    _typeBtn('borrow', tr('borrowBtn'), Icons.arrow_downward_rounded, AppTheme.red),
                  ]),
                ),
                const SizedBox(height: 18),

                _label(tr('fullName')),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(hintText: tr('fullName').replaceAll(' *', ''),
                      prefixIcon: const Icon(Icons.person_outline_rounded)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? tr('fillRequired') : null,
                ),
                const SizedBox(height: 14),

                _label(tr('phone')),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '0600000000',
                      prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? tr('fillRequired') : null,
                ),
                const SizedBox(height: 14),

                _label(tr('amount')),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    suffixText: CurrencyFormatter.symbol(code),
                    suffixStyle: TextStyle(color: auth.themeColor,
                        fontWeight: FontWeight.w700, fontFamily: 'Tajawal'),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return tr('fillRequired');
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null || val <= 0) return tr('fillRequired');
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── #8: Creation Date (editable) ──
                _label(lang == 'ar' ? 'تاريخ الإنشاء' : lang == 'fr' ? 'Date de création' : 'Creation Date'),
                GestureDetector(
                  onTap: () => _pickCreatedAt(lang),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard2, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.event_outlined, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text('${_createdAt.day}/${_createdAt.month}/${_createdAt.year}',
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontFamily: 'Tajawal')),
                      const Spacer(),
                      const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 16),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                _label(tr('dueDate')),
                GestureDetector(
                  onTap: () => _pickDueDate(lang),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard2, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : tr('dueDate'),
                        style: TextStyle(
                            color: _dueDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                            fontFamily: 'Tajawal'),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 18),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                _label(tr('note')),
                TextFormField(
                  controller: _note, maxLines: 3,
                  decoration: InputDecoration(hintText: '...',
                      prefixIcon: const Icon(Icons.notes_outlined), alignLabelWithHint: true),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(isEdit ? tr('saveBtn') : tr('addBtn'),
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _typeBtn(String val, String label, IconData icon, Color color) {
    final sel = _type == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: sel ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? color.withOpacity(0.4) : Colors.transparent),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: sel ? color : AppTheme.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: sel ? color : AppTheme.textSecondary,
                fontWeight: FontWeight.w700, fontFamily: 'Tajawal', fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(
        color: AppTheme.textSecondary, fontWeight: FontWeight.w600,
        fontSize: 13, fontFamily: 'Tajawal')),
  );

  Future<void> _pickCreatedAt(String lang) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: lang == 'ar' ? const Locale('ar') : lang == 'fr' ? const Locale('fr') : const Locale('en'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: context.read<AuthProvider>().themeColor)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _createdAt = d);
  }

  Future<void> _pickDueDate(String lang) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: lang == 'ar' ? const Locale('ar') : lang == 'fr' ? const Locale('fr') : const Locale('en'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: context.read<AuthProvider>().themeColor)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dueDate = d);
  }
}
