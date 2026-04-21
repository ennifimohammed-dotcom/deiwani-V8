import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/debt_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) => MaterialApp(
          title: 'ديوني',
          debugShowCheckedModeBanner: false,
          theme:     AppTheme.buildTheme(Brightness.light, auth.themeColor),
          darkTheme: AppTheme.buildTheme(Brightness.dark,  auth.themeColor),
          themeMode: auth.themeMode,
          locale: Locale(auth.lang),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('fr'),
            Locale('en'),
          ],
          builder: (ctx, child) => Directionality(
            textDirection: auth.lang == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child!,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
