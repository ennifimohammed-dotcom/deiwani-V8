import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../utils/currency_formatter.dart';
import '../services/widget_service.dart';
import '../widgets/debt_card.dart';
import '../widgets/stat_mini_card.dart';
import 'add_debt_screen.dart';
import 'all_debts_screen.dart';
import 'settled_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dp   = context.read<DebtProvider>();
      final auth = context.read<AuthProvider>();
      // Sync all display prefs to DebtProvider for widget labels
      dp.syncPrefs(
        curSymbol:  auth.currencySymbol,
        curCode:    auth.currencyCode,
        lang:       auth.lang,
        isDark:     auth.isDark,
        arabicNums: auth.useArabicNumerals,
      );
      await dp.load();
      // Check if opened from widget tap
      final route = await WidgetService.getPendingRoute();
      if (!mounted) return;
      switch (route) {
        case 'lent':
          _tabs.animateTo(1);
          break;
        case 'borrowed':
          _tabs.animateTo(2);
          break;
        case 'overdue':
        case 'all':
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AllDebtsScreen()));
          break;
        case 'add':
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddDebtScreen()));
          break;
      }
    });
  }

  @override
  void dispose() { _tabs.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dp   = context.watch<DebtProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = auth.lang;
    final code = auth.currencyCode;
    final arabicNum = auth.useArabicNumerals;
    final isPos = dp.netBalance >= 0;
    String tl(String k) => AppTranslations.get(lang, k);

    // Keep DebtProvider in sync whenever auth prefs change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dp.syncPrefs(
        curSymbol:  auth.currencySymbol,
        curCode:    auth.currencyCode,
        lang:       auth.lang,
        isDark:     auth.isDark,
        arabicNums: auth.useArabicNumerals,
      );
    });

    return Scaffold(
      body: Column(children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.gradientFor(auth.themeColor),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [

              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  _iconBtn(Icons.search_rounded, () {
                    setState(() => _searchOpen = !_searchOpen);
                    if (!_searchOpen) { _searchCtrl.clear(); dp.setSearch(''); }
                  }),
                  _iconBtn(Icons.bar_chart_rounded, () => _push(const StatsScreen())),
                  _iconBtn(Icons.settings_outlined,  () => _push(const SettingsScreen())),
                  const Spacer(),
                  // ── Logo always top-right (Directionality-independent) ──
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GestureDetector(
                      onTap: () => _push(const SettingsScreen()),
                      child: Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: AppTheme.gold.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4),
                          )],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

              // Search bar
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _searchOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: tl('search'),
                            hintStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.search, color: Colors.white60),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                          onChanged: dp.setSearch,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),

              // ── Net Balance ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Net Balance label — larger, bold
                          Text(tl('netBalance'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  fontFamily: 'Tajawal')),
                          const SizedBox(height: 6),
                          _formattedBalance(dp.netBalance, code, lang, arabicNum),
                        ],
                      ),
                    ),
                    // موجب / سالب badge — bottom right of balance
                    Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isPos ? AppTheme.green : AppTheme.red).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: (isPos ? AppTheme.green : AppTheme.red).withOpacity(0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              color: isPos ? AppTheme.green : AppTheme.red, size: 15),
                          const SizedBox(width: 4),
                          Text(isPos ? tl('positive') : tl('negative'),
                              style: TextStyle(
                                  color: isPos ? AppTheme.green : AppTheme.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13, fontFamily: 'Tajawal')),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 10),

              // ── Mini stats ── (bold, no overflow)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: StatMiniCard(
                    label: tl('lent'),
                    value: CurrencyFormatter.format(dp.totalLent, code, lang,
                        decimals: 0, useArabicNumerals: arabicNum),
                    icon: Icons.arrow_upward_rounded, color: AppTheme.green)),
                  const SizedBox(width: 8),
                  Expanded(child: StatMiniCard(
                    label: tl('borrowed'),
                    value: CurrencyFormatter.format(dp.totalBorrowed, code, lang,
                        decimals: 0, useArabicNumerals: arabicNum),
                    icon: Icons.arrow_downward_rounded, color: AppTheme.red)),
                  const SizedBox(width: 8),
                  Expanded(child: StatMiniCard(
                    label: tl('overdue'),
                    value: CurrencyFormatter.formatNumber(dp.overdueCount.toDouble(), 0,
                        useArabicNumerals: arabicNum).replaceAll('.00', '').replaceAll('.٠٠', ''),
                    icon: Icons.warning_amber_rounded,
                    color: dp.overdueCount > 0 ? AppTheme.red : Colors.white54)),
                ]),
              ),

              const SizedBox(height: 10),

              // Quick links
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _quickBtn(tl('allDebts'), () => _push(const AllDebtsScreen())),
                  const SizedBox(width: 8),
                  _quickBtn('${tl('settled')} (${dp.settledCount})',
                      () => _push(const SettledScreen())),
                ]),
              ),

              const SizedBox(height: 10),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    controller: _tabs,
                    indicator: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: auth.themeColor,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                        fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.w700),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: '${tl('all')} (${dp.active.length})'),
                      Tab(text: '${tl('lent')} (${dp.lentCount})'),
                      Tab(text: '${tl('borrowed')} (${dp.borrowedCount})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [_list(dp.active), _list(dp.lent), _list(dp.borrowed)],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _push(const AddDebtScreen()),
        backgroundColor: auth.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(tl('addDebt'),
            style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _formattedBalance(double amount, String code, String lang, bool arabicNum) {
    final sym = CurrencyFormatter.symbol(code);
    final num = CurrencyFormatter.formatNumber(amount, 2, useArabicNumerals: arabicNum);
    final isRight = CurrencyFormatter.isRightSymbol(code);
    final baseColor = amount >= 0 ? Colors.white : AppTheme.red;
    final symStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
        color: baseColor.withOpacity(0.85), fontFamily: 'Tajawal');
    final numStyle = TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
        color: baseColor, fontFamily: 'Tajawal');
    return RichText(
      text: TextSpan(children: isRight
          ? [TextSpan(text: num, style: numStyle), TextSpan(text: ' $sym', style: symStyle)]
          : [TextSpan(text: '$sym ', style: symStyle), TextSpan(text: num, style: numStyle)]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  Widget _quickBtn(String label, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white, fontFamily: 'Tajawal')),
      ),
    ),
  );

  Widget _list(List list) {
    final lang = context.read<AuthProvider>().lang;
    if (list.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inbox_rounded, size: 64, color: AppTheme.border),
        const SizedBox(height: 12),
        Text(AppTranslations.get(lang, 'noDebts'),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: list.length,
      itemBuilder: (_, i) => DebtCard(debt: list[i]),
    );
  }

  Future<void> _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
