import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/debt_provider.dart';
import '../services/export_service.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _shareApp(BuildContext context) async {
    final lang = context.read<AuthProvider>().lang;
    final msg = lang == 'ar' ? 'جرّب تطبيق ديوني لإدارة ديونك بذكاء! 💰'
        : lang == 'fr' ? 'Essayez Deiwani! 💰' : 'Try Deiwani! 💰';
    await Share.share(msg);
  }

  Future<void> _rateApp() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.debttracker.app');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final dp    = context.watch<DebtProvider>();
    final lang  = auth.lang;
    final isDark = auth.isDark;
    // In dark mode, text is white
    final labelColor = isDark ? Colors.white : AppTheme.textPrimary;
    String tr(String k) => AppTranslations.get(lang, k);

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
                Text(tr('settings'), style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: Colors.white, fontFamily: 'Tajawal')),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── LANGUAGE ──
              _sectionTitle(tr('language')),
              _settingsCard(child: Column(children: [
                _langItem(context, 'ar', '🇸🇦 العربية',     lang, labelColor),
                _divider(),
                _langItem(context, 'fr', '🇫🇷 Français',    lang, labelColor),
                _divider(),
                _langItem(context, 'en', '🇬🇧 English',     lang, labelColor),
              ])),
              const SizedBox(height: 18),

              // ── CURRENCY ──
              _sectionTitle(tr('currency')),
              _settingsCard(child: Column(
                children: kCurrencies.asMap().entries.map((e) {
                  final idx = e.key; final c = e.value;
                  final sel = auth.currencyCode == c.code;
                  return Column(children: [
                    ListTile(
                      onTap: () => context.read<AuthProvider>()
                          .setCurrency(c.code, c.displayName(lang), c.symbol),
                      leading: _radio(sel, auth.themeColor),
                      title: Text('${c.flag} ${c.displayName(lang)}',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600,
                              color: sel ? auth.themeColor : labelColor)),
                      trailing: Text(c.symbol, style: TextStyle(
                          color: sel ? auth.themeColor : AppTheme.textSecondary,
                          fontWeight: FontWeight.w700)),
                    ),
                    if (idx < kCurrencies.length - 1) _divider(),
                  ]);
                }).toList(),
              )),
              const SizedBox(height: 18),

              // ── THEME (#10) ──
              _sectionTitle(lang == 'ar' ? 'المظهر' : lang == 'fr' ? 'Thème' : 'Theme'),
              _settingsCard(child: Column(children: [
                // Light / Dark
                ListTile(
                  onTap: () => auth.setThemeMode(ThemeMode.light),
                  leading: Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: Text('☀️', style: TextStyle(fontSize: 18)))),
                  title: Text(lang == 'ar' ? 'الوضع الفاتح' : lang == 'fr' ? 'Mode Clair' : 'Light Mode',
                      style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600, color: labelColor)),
                  trailing: !isDark ? _checkMark(auth.themeColor) : null,
                ),
                _divider(),
                ListTile(
                  onTap: () => auth.setThemeMode(ThemeMode.dark),
                  leading: Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: const Color(0xFF1A2340),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: Text('🌙', style: TextStyle(fontSize: 18)))),
                  title: Text(lang == 'ar' ? 'الوضع الداكن' : lang == 'fr' ? 'Mode Sombre' : 'Dark Mode',
                      style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600, color: labelColor)),
                  trailing: isDark ? _checkMark(auth.themeColor) : null,
                ),
                _divider(),
                // 7 color swatches
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lang == 'ar' ? 'لون التطبيق' : lang == 'fr' ? 'Couleur' : 'App Color',
                        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                            fontSize: 13, color: labelColor)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 10, children: AuthProvider.themeColors.map((c) {
                      final isSel = auth.themeColor.value == c.value;
                      return GestureDetector(
                        onTap: () => auth.setThemeColor(c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: c, shape: BoxShape.circle,
                            border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent, width: 3),
                            boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] : [],
                          ),
                          child: isSel
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList()),
                  ]),
                ),
              ])),
              const SizedBox(height: 18),

              // ── SECURITY ──
              _sectionTitle(tr('security')),
              _tile(icon: Icons.lock_outline_rounded, color: auth.themeColor,
                  title: tr('pinLock'), labelColor: labelColor,
                  subtitle: auth.lockEnabled ? tr('pinEnabled') : tr('pinDisabled'),
                  trailing: Switch(value: auth.lockEnabled, activeColor: auth.themeColor,
                      onChanged: (v) => auth.setLockEnabled(v))),
              auth.hasPin
                  ? _tile(icon: Icons.edit_outlined, color: auth.themeColor, labelColor: labelColor,
                      title: tr('changePIN'), subtitle: '4 ****',
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const PinScreen(isChange: true))))
                  : _tile(icon: Icons.add_circle_outline_rounded, color: AppTheme.green, labelColor: labelColor,
                      title: tr('createPIN'), subtitle: tr('security'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const PinScreen(isSetup: true)))),
              const SizedBox(height: 18),

              // ── DATA ──
              _sectionTitle(tr('data')),
              _tile(icon: Icons.file_download_outlined, color: AppTheme.green, labelColor: labelColor,
                  title: tr('exportExcel'), subtitle: tr('exportSub'),
                  onTap: () => ExportService.exportToExcel(dp.active, auth.displayCurrency)),
              _tile(icon: Icons.delete_outline_rounded, color: AppTheme.red, labelColor: labelColor,
                  title: tr('deleteAll'), subtitle: tr('deleteAllSub'),
                  onTap: () => _confirmDeleteAll(context, dp, lang)),
              const SizedBox(height: 18),

              // ── SHARE & RATE ──
              _sectionTitle(lang == 'ar' ? 'المشاركة والتقييم'
                  : lang == 'fr' ? 'Partage & Évaluation' : 'Share & Rate'),
              _tile(icon: Icons.share_outlined, color: auth.themeColor, labelColor: labelColor,
                  title: lang == 'ar' ? 'مشاركة التطبيق' : lang == 'fr' ? "Partager l'app" : 'Share App',
                  subtitle: lang == 'ar' ? 'أخبر أصدقاءك عن ديوني'
                      : lang == 'fr' ? 'Parlez de Deiwani' : 'Tell your friends about Deiwani',
                  onTap: () => _shareApp(context)),
              _tile(icon: Icons.star_outline_rounded, color: AppTheme.gold, labelColor: labelColor,
                  title: lang == 'ar' ? 'تقييم التطبيق' : lang == 'fr' ? "Évaluer l'app" : 'Rate App',
                  subtitle: lang == 'ar' ? 'ساعدنا بتقييمك' : lang == 'fr' ? 'Aidez-nous' : 'Help us improve',
                  onTap: _rateApp),
              const SizedBox(height: 18),

              // ── ABOUT (#11: logo instead of old icon) ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
                child: Column(children: [
                  // #11: App logo instead of old wallet icon
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.25),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(tr('appTitle'), style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20,
                      fontFamily: 'Tajawal', color: labelColor)),
                  const SizedBox(height: 4),
                  Text(tr('version'), style: TextStyle(color: auth.themeColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('إدارة ديونك بذكاء', textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13,
                          fontFamily: 'Tajawal')),
                ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _radio(bool sel, Color color) => Container(
    width: 24, height: 24,
    decoration: BoxDecoration(shape: BoxShape.circle,
        color: sel ? color : AppTheme.border),
    child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
  );

  Widget _checkMark(Color c) => Container(
    width: 22, height: 22,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    child: const Icon(Icons.check, size: 13, color: Colors.white),
  );

  Widget _langItem(BuildContext context, String code, String label,
      String current, Color labelColor) {
    final sel = current == code;
    return ListTile(
      onTap: () => context.read<AuthProvider>().setLanguage(code),
      leading: _radio(sel, context.read<AuthProvider>().themeColor),
      title: Text(label, style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600,
          color: sel ? context.read<AuthProvider>().themeColor : labelColor)),
    );
  }

  Widget _settingsCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border)),
    child: child,
  );

  Widget _divider() => const Divider(height: 1, color: AppTheme.border, indent: 16, endIndent: 16);

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(color: AppTheme.textSecondary,
        fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _tile({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required Color labelColor,
    Widget? trailing, VoidCallback? onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border)),
    child: ListTile(
      onTap: onTap,
      leading: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: TextStyle(fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600, fontSize: 14, color: labelColor)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Tajawal',
          color: AppTheme.textSecondary, fontSize: 12)),
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 14)
          : null),
    ),
  );

  void _confirmDeleteAll(BuildContext context, DebtProvider dp, String lang) {
    String tr(String k) => AppTranslations.get(lang, k);
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(tr('deleteAllTitle'), style: const TextStyle(fontFamily: 'Tajawal')),
      content: Text(tr('deleteAllMsg'), style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'), style: const TextStyle(fontFamily: 'Tajawal'))),
        TextButton(
          onPressed: () async { await dp.deleteAll(); if (context.mounted) Navigator.pop(context); },
          child: Text(tr('confirm'), style: const TextStyle(color: AppTheme.red, fontFamily: 'Tajawal')),
        ),
      ],
    ));
  }
}
