class GamificationState {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final List<String> earnedBadges;
  final List<String> completedQuestsToday;
  final List<String> completedQuestsWeek;
  final String lastHealthyDayKey;
  final int todayLogCount;

  GamificationState({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.earnedBadges = const [],
    this.completedQuestsToday = const [],
    this.completedQuestsWeek = const [],
    this.lastHealthyDayKey = '',
    this.todayLogCount = 0,
  });

  int get level {
    final thresholds = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 4000, 5000];
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (totalXp >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  int get xpForNextLevel {
    final thresholds = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 4000, 5000];
    if (level >= thresholds.length) return totalXp;
    return thresholds[level] - totalXp;
  }

  double get levelProgress {
    final thresholds = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 4000, 5000];
    if (level >= thresholds.length) return 1.0;
    final current = thresholds[level - 1];
    final next = thresholds[level];
    return (totalXp - current) / (next - current);
  }

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'earnedBadges': earnedBadges,
        'completedQuestsToday': completedQuestsToday,
        'completedQuestsWeek': completedQuestsWeek,
        'lastHealthyDayKey': lastHealthyDayKey,
        'todayLogCount': todayLogCount,
      };

  factory GamificationState.fromJson(Map<String, dynamic> json) =>
      GamificationState(
        totalXp: json['totalXp'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        earnedBadges: List<String>.from(json['earnedBadges'] ?? []),
        completedQuestsToday:
            List<String>.from(json['completedQuestsToday'] ?? []),
        completedQuestsWeek:
            List<String>.from(json['completedQuestsWeek'] ?? []),
        lastHealthyDayKey: json['lastHealthyDayKey'] as String? ?? '',
        todayLogCount: json['todayLogCount'] as int? ?? 0,
      );

  GamificationState copyWith({
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    List<String>? earnedBadges,
    List<String>? completedQuestsToday,
    List<String>? completedQuestsWeek,
    String? lastHealthyDayKey,
    int? todayLogCount,
  }) =>
      GamificationState(
        totalXp: totalXp ?? this.totalXp,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        earnedBadges: earnedBadges ?? this.earnedBadges,
        completedQuestsToday:
            completedQuestsToday ?? this.completedQuestsToday,
        completedQuestsWeek: completedQuestsWeek ?? this.completedQuestsWeek,
        lastHealthyDayKey: lastHealthyDayKey ?? this.lastHealthyDayKey,
        todayLogCount: todayLogCount ?? this.todayLogCount,
      );
}