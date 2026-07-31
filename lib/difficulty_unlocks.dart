import 'package:shared_preferences/shared_preferences.dart';

import 'game/game_logic.dart';

class DifficultyUnlocks {
  static const String maxUnlockedLevelKey = 'max_unlocked_difficulty_level';

  static Future<int> loadMaxUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(maxUnlockedLevelKey) ?? 1;
    return stored.clamp(1, AIDifficulty.values.length);
  }

  static Future<int> unlockThrough(AIDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(maxUnlockedLevelKey) ?? 1;
    final target = difficulty.level.clamp(1, AIDifficulty.values.length);
    final updated = current > target ? current : target;
    await prefs.setInt(maxUnlockedLevelKey, updated);
    return updated;
  }
}
