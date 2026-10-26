/// A measured game result for one named skill. The app only records values
/// explicitly reported by a game module; an unmeasured skill stays absent.
class GameSkillRating {
  const GameSkillRating(this.name, this.value);
  final String name;
  final int? value;
}

class SkillProgress {
  SkillProgress({Map<String, int>? bestScores})
      : bestScores = bestScores ?? <String, int>{};

  final Map<String, int> bestScores;

  void record(String skill, int value) {
    if (skill.trim().isEmpty) return;
    final score = value.clamp(0, 100).toInt();
    if (score > (bestScores[skill] ?? -1)) bestScores[skill] = score;
  }

  List<GameSkillRating> get ratings => bestScores.entries
      .map((entry) => GameSkillRating(entry.key, entry.value)).toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  Map<String, Object> toJson() => {'version': 1, 'bestScores': bestScores};

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    final raw = json['bestScores'];
    return SkillProgress(bestScores: raw is Map
        ? raw.map((key, value) => MapEntry(key.toString(),
            value is num ? value.toInt().clamp(0, 100).toInt() : 0))
        : <String, int>{});
  }
}
