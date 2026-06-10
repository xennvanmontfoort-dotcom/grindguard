import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/disclaimer_banner.dart';
import '../../core/widgets/neon_button.dart';
import '../../models/gaming_session.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';

class GamingSessionScreen extends StatefulWidget {
  const GamingSessionScreen({super.key});

  @override
  State<GamingSessionScreen> createState() => _GamingSessionScreenState();
}

class _GamingSessionScreenState extends State<GamingSessionScreen> {
  Timer? _timer;
  GamingSession? _session;
  int _elapsedSeconds = 0;


  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final app = context.read<AppProvider>();
    final existing = app.activeSession;
    if (existing != null) {
      setState(() {
        _session = existing;
        _elapsedSeconds = DateTime.now().difference(existing.startTime).inSeconds;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      setState(() => _elapsedSeconds++);
      final breakInterval = (context.read<AppProvider>().profile?.breakIntervalMinutes ?? 50) * 60;
      if (_elapsedSeconds > 0 && _elapsedSeconds % breakInterval == 0 && _session != null) {
        await _promptBreak();
      }
    });
  }

  Future<void> _promptBreak() async {
    HapticFeedback.heavyImpact();
    await NotificationService().showBreakReminder();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('⏸️ Pro Reset!', style: GoogleFonts.orbitron(color: AppColors.neonGreen)),
        content: Text(
          'Tijd voor je break!\n\n'
          '✅ Staan & stretch\n'
          '✅ Hydrate (1 glas water)\n'
          '✅ 20-20-20 ogen\n'
          '✅ 5 min lopen\n\n'
          'Je aim reset > nog 1 game.',
          style: GoogleFonts.exo2(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_session != null) {
                final updated = _session!.copyWith(
                  breaksPrompted: _session!.breaksPrompted + 1,
                );
                await context.read<AppProvider>().updateGamingSession(updated);
                setState(() => _session = updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Later...'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_session != null) {
                final updated = _session!.copyWith(
                  breaksPrompted: _session!.breaksPrompted + 1,
                  breaksTaken: _session!.breaksTaken + 1,
                );
                await context.read<AppProvider>().updateGamingSession(updated);
                setState(() => _session = updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Break genomen! 💪'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession() async {
    final session = await context.read<AppProvider>().startGamingSession();
    setState(() {
      _session = session;
      _elapsedSeconds = 0;
    });
    _startTimer();
  }

  Future<void> _endSession() async {
    _timer?.cancel();
    if (_session != null) {
      final totalMin = (_elapsedSeconds / 60).round();
      final updated = _session!.copyWith(
        totalMinutes: totalMin,
        isActive: false,
        endTime: DateTime.now(),
      );
      await context.read<AppProvider>().updateGamingSession(updated);
      await context.read<AppProvider>().endGamingSession(updated);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0) return '${h}u ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _session?.isActive ?? false;
    final breakInterval = context.watch<AppProvider>().profile?.breakIntervalMinutes ?? 50;
    final compliance = _session?.breakCompliance ?? 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Gaming Session 🎮')),
      body: Column(
        children: [
          const DisclaimerBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isActive ? 'GRINDING...' : 'Klaar om te grinden?',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      color: AppColors.neonGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formattedTime,
                    style: GoogleFonts.orbitron(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonPurple,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Break elke $breakInterval min',
                      style: GoogleFonts.exo2(color: AppColors.textSecondary),
                    ),
                    Text(
                      'Compliance: ${(compliance * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.exo2(color: AppColors.neonGreen),
                    ),
                  ],
                  const SizedBox(height: 48),
                  if (!isActive)
                    NeonButton(
                      label: 'Start Session 🚀',
                      color: AppColors.neonGreen,
                      onPressed: _startSession,
                    )
                  else ...[
                    NeonButton(
                      label: 'Break genomen ✅',
                      outlined: true,
                      color: AppColors.accentBlue,
                      onPressed: () async {
                        if (_session != null) {
                          final updated = _session!.copyWith(
                            breaksTaken: _session!.breaksTaken + 1,
                          );
                          await context.read<AppProvider>().updateGamingSession(updated);
                          setState(() => _session = updated);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    NeonButton(
                      label: 'End Session',
                      color: AppColors.danger,
                      onPressed: _endSession,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}