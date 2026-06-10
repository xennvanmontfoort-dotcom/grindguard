/// App-brede constanten voor GrindGuard.
class AppConstants {
  static const String appName = 'GrindGuard';
  static const String appTagline = 'Fortnite Pro Health Coach';

  // Standaard dagelijkse doelen
  static const double defaultWaterGoalLiters = 3.0;
  static const double defaultSleepGoalHours = 9.0;
  static const int defaultBreakIntervalMinutes = 50;
  static const int defaultMovementGoalMinutes = 30;

  // XP beloningen
  static const int xpSymptomLog = 25;
  static const int xpHydrationLog = 10;
  static const int xpNutritionLog = 15;
  static const int xpSleepLog = 20;
  static const int xpGamingSession = 30;
  static const int xpMovementLog = 15;
  static const int xpQuestComplete = 50;
  static const int xpDailyGoalComplete = 40;

  // Level drempels
  static const List<int> levelThresholds = [
    0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 4000, 5000,
  ];

  // Symptom triggers
  static const List<String> symptomTriggers = [
    'Opstaan',
    'Lange gaming sessie >2u',
    'Weinig gedronken',
    'Maaltijd overgeslagen',
    'Stress/tilt',
    'Warm',
    'Veel schermtijd',
    'Anders',
  ];

  static const List<String> associatedSymptoms = [
    'Misselijk',
    'Hartkloppingen',
    'Wazig zicht',
    'Hoofdpijn',
    'Brain fog',
    'Zweten/bleek',
    'Kortademig',
    'Anders',
  ];

  static const List<String> whatHelpedOptions = [
    'Water',
    'Zitten/liggen',
    'Frisse lucht',
    'Ademhaling',
    'Eten',
  ];

  static const List<String> mainConcerns = [
    'Duizeligheid',
    'Flauwvallen',
    'Hoofdpijn',
    'Brain fog',
    'Vermoeidheid',
    'Hartkloppingen',
    'Groei/spurt',
    'Anders',
  ];
}