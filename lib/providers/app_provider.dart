import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/coach_tips.dart';
import '../core/utils/date_utils.dart';
import '../models/gamification_state.dart';
import '../models/gaming_session.dart';
import '../models/hydration_log.dart';
import '../models/movement_log.dart';
import '../models/nutrition_log.dart';
import '../models/reminder_settings.dart';
import '../models/sleep_log.dart';
import '../models/symptom_log.dart';
import '../models/user_profile.dart';
import '../services/gamification_service.dart';
import '../services/insights_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';

/// Centrale app state — alle data en acties.
class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final GamificationService _gamification = GamificationService();
  final InsightsService _insights = InsightsService();
  final NotificationService _notifications = NotificationService();
  final PdfService _pdf = PdfService();
  final _uuid = const Uuid();

  bool _initialized = false;
  UserProfile? _profile;
  GamificationState _gamificationState = GamificationState();
  ReminderSettings _reminders = const ReminderSettings();

  List<SymptomLog> _symptoms = [];
  List<HydrationLog> _hydration = [];
  List<NutritionLog> _nutrition = [];
  List<SleepLog> _sleep = [];
  List<GamingSession> _gaming = [];
  MovementLog? _todayMovement;

  String? _lastXpMessage;
  String? _newBadgeEarned;
  bool _showConfetti = false;

  bool get initialized => _initialized;
  UserProfile? get profile => _profile;
  GamificationState get gamification => _gamificationState;
  ReminderSettings get reminders => _reminders;
  List<SymptomLog> get symptoms => _symptoms;
  List<HydrationLog> get hydration => _hydration;
  List<NutritionLog> get nutrition => _nutrition;
  List<SleepLog> get sleep => _sleep;
  List<GamingSession> get gaming => _gaming;
  MovementLog? get todayMovement => _todayMovement;
  GamingSession? get activeSession => _storage.getActiveSession();
  String? get lastXpMessage => _lastXpMessage;
  String? get newBadgeEarned => _newBadgeEarned;
  bool get showConfetti => _showConfetti;

  bool get isOnboarded => _profile?.onboardingComplete ?? false;

  Future<void> init() async {
    await _storage.init();
    await _notifications.init();
    _profile = _storage.getProfile();
    _gamificationState = _storage.getGamification();
    _reminders = _storage.getReminders();
    _loadAllData();
    await _notifications.scheduleReminders(_reminders);
    _initialized = true;
    notifyListeners();
  }

  void _loadAllData() {
    _symptoms = _storage.getSymptoms();
    _hydration = _storage.getHydrationLogs();
    _nutrition = _storage.getNutritionLogs();
    _sleep = _storage.getSleepLogs();
    _gaming = _storage.getGamingSessions();
    _todayMovement = _storage.getMovementForDay(AppDateUtils.dayKey(DateTime.now()));
  }

  // --- Today's stats ---
  double get todayWaterLiters {
    final key = AppDateUtils.dayKey(DateTime.now());
    final ml = _hydration
        .where((h) => AppDateUtils.dayKey(h.timestamp) == key)
        .fold<double>(0, (s, h) => s + h.amountMl);
    return ml / 1000;
  }

  NutritionLog get todayNutrition {
    final key = AppDateUtils.dayKey(DateTime.now());
    return _nutrition.firstWhere(
      (n) => AppDateUtils.dayKey(n.date) == key,
      orElse: () => NutritionLog(id: 'today', date: DateTime.now()),
    );
  }

  SleepLog? get todaySleep {
    final key = AppDateUtils.dayKey(DateTime.now());
    for (final s in _sleep) {
      if (AppDateUtils.dayKey(s.date) == key) return s;
    }
    return null;
  }

  double get todayGamingHours {
    final key = AppDateUtils.dayKey(DateTime.now());
    return _gaming
        .where((g) => AppDateUtils.dayKey(g.startTime) == key)
        .fold<double>(0, (s, g) => s + g.hoursPlayed);
  }

  String get dailyTip {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return CoachTips.dailyTips[dayOfYear % CoachTips.dailyTips.length];
  }

  String get motivationalQuote {
    final idx = DateTime.now().day % CoachTips.motivationalQuotes.length;
    return CoachTips.motivationalQuotes[idx];
  }

  // --- Onboarding ---
  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile.copyWith(onboardingComplete: true);
    await _storage.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    await _storage.saveProfile(profile);
    notifyListeners();
  }

  // --- Symptom logging ---
  Future<void> logSymptom({
    required int severity,
    required List<String> triggers,
    required List<String> symptoms,
    String? notes,
    List<String> whatHelped = const [],
    bool nearFaint = false,
    bool fullFaint = false,
  }) async {
    final log = SymptomLog(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      severity: severity,
      triggers: triggers,
      symptoms: symptoms,
      notes: notes,
      whatHelped: whatHelped,
      nearFaint: nearFaint,
      fullFaint: fullFaint,
    );
    await _storage.saveSymptom(log);
    _symptoms.insert(0, log);
    await _awardXp('symptom');
    notifyListeners();
  }

  Future<void> deleteSymptom(String id) async {
    await _storage.deleteSymptom(id);
    _symptoms.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // --- Hydration ---
  Future<void> addWater(double ml, {bool electrolyte = false}) async {
    final log = HydrationLog(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      amountMl: ml,
      isElectrolyte: electrolyte,
    );
    await _storage.saveHydration(log);
    _hydration.add(log);
    await _awardXp('hydration');
    _updateStreak();
    notifyListeners();
  }

  // --- Nutrition ---
  Future<void> updateNutrition({
    bool? breakfast,
    bool? lunch,
    bool? dinner,
    bool? iron,
    String? notes,
  }) async {
    final key = AppDateUtils.dayKey(DateTime.now());
    var existing = _storage.getNutritionForDay(key);
    existing ??= NutritionLog(id: _uuid.v4(), date: DateTime.now());
    final updated = existing.copyWith(
      hadBreakfast: breakfast,
      hadLunch: lunch,
      hadDinner: dinner,
      hadIronRichFood: iron,
      notes: notes,
    );
    await _storage.saveNutrition(updated);
    _nutrition.removeWhere((n) => AppDateUtils.dayKey(n.date) == key);
    _nutrition.add(updated);
    await _awardXp('nutrition');
    _updateStreak();
    notifyListeners();
  }

  // --- Sleep ---
  Future<void> logSleep({
    required double hours,
    int quality = 3,
    DateTime? bedTime,
    DateTime? wakeTime,
    String? notes,
  }) async {
    final key = AppDateUtils.dayKey(DateTime.now());
    final log = SleepLog(
      id: _uuid.v4(),
      date: DateTime.now(),
      hoursSlept: hours,
      qualityStars: quality,
      bedTime: bedTime,
      wakeTime: wakeTime,
      notes: notes,
    );
    await _storage.saveSleep(log);
    _sleep.removeWhere((s) => AppDateUtils.dayKey(s.date) == key);
    _sleep.add(log);
    await _awardXp('sleep');
    _updateStreak();
    notifyListeners();
  }

  // --- Gaming ---
  Future<GamingSession> startGamingSession() async {
    final existing = _storage.getActiveSession();
    if (existing != null) return existing;

    final session = GamingSession(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      isActive: true,
    );
    await _storage.saveGamingSession(session);
    _gaming.insert(0, session);
    notifyListeners();
    return session;
  }

  Future<void> updateGamingSession(GamingSession session) async {
    await _storage.saveGamingSession(session);
    final idx = _gaming.indexWhere((g) => g.id == session.id);
    if (idx >= 0) _gaming[idx] = session;
    notifyListeners();
  }

  Future<void> endGamingSession(GamingSession session) async {
    final ended = session.copyWith(
      isActive: false,
      endTime: DateTime.now(),
    );
    await _storage.saveGamingSession(ended);
    final idx = _gaming.indexWhere((g) => g.id == session.id);
    if (idx >= 0) _gaming[idx] = ended;
    await _awardXp('gaming');
    notifyListeners();
  }

  // --- Movement ---
  Future<void> updateMovement({
    int? steps,
    int? antiSitMinutes,
    bool? postureCheck,
  }) async {
    var existing = _todayMovement ??
        MovementLog(id: _uuid.v4(), date: DateTime.now());
    existing = existing.copyWith(
      steps: steps != null ? existing.steps + steps : null,
      antiSitMinutes: antiSitMinutes != null
          ? existing.antiSitMinutes + antiSitMinutes
          : null,
      postureCheckDone: postureCheck ?? existing.postureCheckDone,
    );
    await _storage.saveMovement(existing);
    _todayMovement = existing;
    if (steps != null || antiSitMinutes != null || postureCheck == true) {
      await _awardXp('movement');
    }
    notifyListeners();
  }

  // --- Reminders ---
  Future<void> updateReminders(ReminderSettings settings) async {
    _reminders = settings;
    await _storage.saveReminders(settings);
    await _notifications.scheduleReminders(settings);
    notifyListeners();
  }

  // --- Insights ---
  List<InsightResult> get insights => _insights.generateInsights(
        symptoms: _symptoms,
        hydration: _hydration,
        sleep: _sleep,
        gaming: _gaming,
        profile: _profile,
      );

  WeeklySummary get weeklySummary => _insights.getWeeklySummary(
        symptoms: _symptoms,
        hydration: _hydration,
        sleep: _sleep,
        gaming: _gaming,
      );

  List<Map<String, dynamic>> get symptomChartData =>
      _insights.symptomChartData(_symptoms);

  Future<void> exportPdf() async {
    if (_profile == null) return;
    await _pdf.exportDoctorReport(
      profile: _profile!,
      symptoms: _symptoms,
      hydration: _hydration,
      sleep: _sleep,
      nutrition: _nutrition,
      gaming: _gaming,
      summary: weeklySummary,
      insights: insights,
    );
  }

  // --- Coach ---
  List<CoachTip> get availableTips {
    final level = _gamificationState.level;
    return CoachTips.all.where((t) => t.minLevel <= level).toList();
  }

  List<CoachTip> get personalizedTips {
    final tips = <CoachTip>[];
    if (_symptoms.any((s) => s.triggers.contains('Weinig gedronken'))) {
      tips.add(CoachTips.all.firstWhere((t) => t.id == 'h1'));
    }
    if (_symptoms.any((s) => s.triggers.contains('Lange gaming sessie >2u'))) {
      tips.add(CoachTips.all.firstWhere((t) => t.id == 'e1'));
    }
    if (_profile?.inGrowthSpurt == true) {
      tips.add(CoachTips.all.firstWhere((t) => t.id == 'g1'));
    }
    if (tips.isEmpty) {
      tips.add(CoachTips.all[DateTime.now().day % CoachTips.all.length]);
    }
    return tips;
  }

  String askCoach(String question) {
    final q = question.toLowerCase();
    if (q.contains('duizelig') || q.contains('dizzy')) {
      return 'Duizelig na opstaan of lange sessies? Normaal bij groei soms. '
          'Drink water, sta langzaam op, neem breaks. Blijft het? → huisarts. '
          'GEEN medisch advies — bij erge klachten altijd dokter!';
    }
    if (q.contains('water') || q.contains('drink')) {
      return 'Yo bro, 3L per dag is de meta. Elke ranked game = 1 glas. '
          'Electrolytes na lange grind. Hydrate die aim! 💧';
    }
    if (q.contains('slaap') || q.contains('sleep')) {
      return '9u slaap = cracked aim. Geen ranked na middernacht. '
          'Wind-down 1u voor bed: geen scherm, rustige vibe.';
    }
    if (q.contains('tilt') || q.contains('stress')) {
      return 'Box breathing: 4-4-4-4. Na 2 losses = 5 min pauze. '
          'Tilt is de echte boss fight — calm mind = betere plays.';
    }
    return 'Goede vraag! Check de Coach Hub tips of log je symptomen '
        'zodat ik betere personalized tips kan geven. En bij rode vlaggen: huisarts/112!';
  }

  // --- Gamification helpers ---
  Future<void> _awardXp(String logType) async {
    final gain = _gamification.recordLog(_gamificationState, logType);
    _gamificationState = _gamificationState.copyWith(
      totalXp: _gamificationState.totalXp + gain.amount,
      todayLogCount: _gamificationState.todayLogCount + 1,
    );
    _lastXpMessage = gain.reason;

    final newBadges = _gamification.checkBadges(
      state: _gamificationState,
      symptoms: _symptoms,
      hydration: _hydration,
      sleep: _sleep,
      nutrition: _nutrition,
      gaming: _gaming,
    );

    if (newBadges.isNotEmpty) {
      _newBadgeEarned = newBadges.first;
      _gamificationState = _gamificationState.copyWith(
        earnedBadges: [..._gamificationState.earnedBadges, ...newBadges],
      );
    }

    if (gain.levelUp) {
      _lastXpMessage = '🎉 Level ${gain.newLevel} bereikt!';
    }

    await _storage.saveGamification(_gamificationState);
  }

  void _updateStreak() {
    final updated = _gamification.updateStreak(
      _gamificationState,
      waterLiters: todayWaterLiters,
      waterGoal: _profile?.waterGoalLiters ?? 3.0,
      sleepHours: todaySleep?.hoursSlept ?? 0,
      sleepGoal: _profile?.sleepGoalHours ?? 9.0,
      mealsEaten: todayNutrition.mealsEaten,
    );

    if (updated.currentStreak > _gamificationState.currentStreak) {
      if (updated.currentStreak % 7 == 0) {
        _showConfetti = true;
      }
    }

    _gamificationState = updated;
    _storage.saveGamification(_gamificationState);
  }

  void clearConfetti() {
    _showConfetti = false;
    notifyListeners();
  }

  void clearXpMessage() {
    _lastXpMessage = null;
    _newBadgeEarned = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> get questProgress => _gamification.getQuestProgress(
        state: _gamificationState,
        todayWaterLiters: todayWaterLiters,
        waterGoal: _profile?.waterGoalLiters ?? 3.0,
        todaySleepHours: todaySleep?.hoursSlept ?? 0,
        ironToday: todayNutrition.hadIronRichFood,
        weekBreakCompliance: weeklySummary.breakCompliance,
        weekHealthyDays: _gamificationState.currentStreak.clamp(0, 7),
        weekSymptomLogs: weeklySummary.symptomCount,
        profile: _profile,
      );
}
