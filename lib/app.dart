import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';

class GrindGuardApp extends StatelessWidget {
  const GrindGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrindGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [
        Locale('nl', 'NL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (!app.initialized) {
          return const _SplashScreen();
        }
        if (!app.isOnboarded) {
          return const OnboardingScreen();
        }
        return const MainShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛡️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'GRINDGUARD',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.neonPurple,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.neonGreen),
            const SizedBox(height: 8),
            const Text('Loading...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}