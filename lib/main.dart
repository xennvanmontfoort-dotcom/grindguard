import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_provider.dart';

/// GrindGuard: Fortnite Pro Health Coach
/// Werkt op web (Netlify), iOS en Android.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Cleane URLs op Netlify (geen # in de URL)
    usePathUrlStrategy();
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF14141F),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const GrindGuardApp(),
    ),
  );
}