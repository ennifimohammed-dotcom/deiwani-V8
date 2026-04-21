import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/debt_provider.dart';
import 'pin_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fade   = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale  = Tween<double>(begin: 0.72, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _slideUp = Tween<double>(begin: 22.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.init();
    await context.read<DebtProvider>().load();
    await Future.delayed(const Duration(milliseconds: 2300));
    if (!mounted) return;
    if (auth.hasPin && auth.lockEnabled) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PinScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B2B5E), Color(0xFF243572), Color(0xFF1A2555)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Icon — slightly reduced (180 instead of 220)
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC9A84C).withOpacity(0.35),
                        blurRadius: 48, spreadRadius: 4, offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Subtitle — bolder, aligned
              AnimatedBuilder(
                animation: _slideUp,
                builder: (_, child) =>
                    Transform.translate(offset: Offset(0, _slideUp.value), child: child),
                child: Text(
                  'إدارة ديونك بذكاء',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700, // bolder
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Tajawal',
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                  color: const Color(0xFFC9A84C).withOpacity(0.7),
                  strokeWidth: 2.5,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
