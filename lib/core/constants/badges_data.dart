/// Badges met Fortnite flair.
class BadgeTemplate {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String requirement;

  const BadgeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.requirement,
  });
}

class BadgesData {
  static const List<BadgeTemplate> all = [
    BadgeTemplate(
      id: 'streak_7',
      title: 'Victory Royale',
      description: '7 dagen streak!',
      emoji: '🏆',
      requirement: '7_day_streak',
    ),
    BadgeTemplate(
      id: 'streak_30',
      title: 'Season Champion',
      description: '30 dagen streak!',
      emoji: '👑',
      requirement: '30_day_streak',
    ),
    BadgeTemplate(
      id: 'water_7',
      title: 'Hydration Hero',
      description: '7 dagen waterdoel gehaald',
      emoji: '💧',
      requirement: 'water_7_days',
    ),
    BadgeTemplate(
      id: 'breaks_pro',
      title: 'Break Master',
      description: '80%+ breaks een week',
      emoji: '⏸️',
      requirement: 'break_master',
    ),
    BadgeTemplate(
      id: 'posture',
      title: 'Build Master',
      description: 'Consistente houding checks',
      emoji: '🏗️',
      requirement: 'posture_10',
    ),
    BadgeTemplate(
      id: 'first_log',
      title: 'Rookie Scout',
      description: 'Eerste symptom log',
      emoji: '📋',
      requirement: 'first_symptom',
    ),
    BadgeTemplate(
      id: 'sleep_pro',
      title: 'Dream Warrior',
      description: '7 dagen goede slaap',
      emoji: '😴',
      requirement: 'sleep_7_days',
    ),
    BadgeTemplate(
      id: 'iron_week',
      title: 'Iron Builder',
      description: '5 dagen ijzerrijk eten',
      emoji: '🥩',
      requirement: 'iron_5_days',
    ),
    BadgeTemplate(
      id: 'level_5',
      title: 'Pro Player',
      description: 'Level 5 bereikt',
      emoji: '⭐',
      requirement: 'level_5',
    ),
    BadgeTemplate(
      id: 'near_faint',
      title: 'Awareness Ace',
      description: 'Bijna-flauwvallen gelogd — goed bezig!',
      emoji: '🛡️',
      requirement: 'near_faint_log',
    ),
  ];
}