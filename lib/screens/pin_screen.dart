import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import 'home_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  final bool isChange;
  const PinScreen(
      {super.key, this.isSetup = false, this.isChange = false});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirm = '';
  bool _confirming = false;
  bool _error = false;
  String _errorMsg = '';
  int _attempts = 0;
  late AnimationController _shake;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shake);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  String get _lang => context.read<AuthProvider>().lang;
  String tr(String k) => AppTranslations.get(_lang, k);

  void _press(String k) {
    setState(() {
      _error = false;
      if (k == 'del') {
        if (_confirming && _confirm.isNotEmpty) {
          _confirm = _confirm.substring(0, _confirm.length - 1);
        } else if (!_confirming && _pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
        return;
      }
      if (_confirming) {
        if (_confirm.length < 4) {
          _confirm += k;
          if (_confirm.length == 4) _doConfirm();
        }
      } else {
        if (_pin.length < 4) {
          _pin += k;
          if (_pin.length == 4) {
            if (widget.isSetup || widget.isChange) {
              setState(() => _confirming = true);
            } else {
              _doVerify();
            }
          }
        }
      }
    });
  }

  Future<void> _doVerify() async {
    final ok = await context.read<AuthProvider>().verifyPin(_pin);
    if (ok) {
      if (!mounted) return;
      if (widget.isChange) {
        Navigator.pop(context);
        return;
      }
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      _attempts++;
      _shake.forward(from: 0);
      setState(() {
        _error = true;
        _errorMsg = tr('wrongPin');
        _pin = '';
      });
    }
  }

  Future<void> _doConfirm() async {
    if (_pin == _confirm) {
      await context.read<AuthProvider>().setPin(_pin);
      if (!mounted) return;
      if (widget.isChange) {
        Navigator.pop(context);
        return;
      }
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      _shake.forward(from: 0);
      setState(() {
        _error = true;
        _errorMsg = tr('mismatch');
        _pin = '';
        _confirm = '';
        _confirming = false;
      });
    }
  }

  void _showForgotPin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(tr('forgotPin'),
            style: const TextStyle(fontFamily: 'Tajawal')),
        content: Text(tr('forgotPinMsg'),
            style: const TextStyle(
                fontFamily: 'Tajawal', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ok'),
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  String get _title {
    if (widget.isChange) {
      return _confirming ? tr('confirmPin') : tr('changePIN');
    }
    if (widget.isSetup) {
      return _confirming ? tr('confirmPin') : tr('createPinTitle');
    }
    return tr('enterPin');
  }

  String get _subtitle {
    if (widget.isSetup && !_confirming) return tr('chooseCode');
    if (_confirming) return tr('reenterCode');
    return tr('enterCode');
  }

  @override
  Widget build(BuildContext context) {
    final current = _confirming ? _confirm : _pin;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 50),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.gold.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text(_title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Tajawal')),
            const SizedBox(height: 8),
            Text(_subtitle,
                style: const TextStyle(
                    fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(_error ? _shakeAnim.value : 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < current.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 10),
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? (_error
                                ? AppTheme.red
                                : AppTheme.gold)
                            : Colors.transparent,
                        border: Border.all(
                          color: filled
                              ? (_error
                                  ? AppTheme.red
                                  : AppTheme.gold)
                              : Colors.white54,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            if (_error) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.red.withOpacity(0.4)),
                ),
                child: Text(_errorMsg,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Tajawal')),
              ),
            ],
            const Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', 'del'],
                  ])
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: row.map(_buildKey).toList(),
                      ),
                    ),
                ],
              ),
            ),
            if (!widget.isSetup && !widget.isChange) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _showForgotPin,
                child: Text(tr('forgotPin'),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Tajawal',
                        fontSize: 14)),
              ),
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildKey(String k) {
    if (k.isEmpty) return const SizedBox(width: 72, height: 72);
    return GestureDetector(
      onTap: () => _press(k),
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: k == 'del'
              ? AppTheme.primary.withOpacity(0.08)
              : AppTheme.bg,
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: k == 'del'
              ? const Icon(Icons.backspace_outlined,
                  color: AppTheme.primary, size: 22)
              : Text(k,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
        ),
      ),
    );
  }
}
