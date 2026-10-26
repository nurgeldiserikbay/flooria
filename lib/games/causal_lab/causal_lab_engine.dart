import 'dart:math';

/// Simple causal models used to make an experiment informative.
enum CauseRule { both, either, sunOnly, waterOnly, exactlyOne, always, never }

extension CauseRuleText on CauseRule {
  String get label => switch (this) {
        CauseRule.both => 'SUN AND WATER',
        CauseRule.either => 'SUN OR WATER',
        CauseRule.sunOnly => 'SUN ONLY',
        CauseRule.waterOnly => 'WATER ONLY',
        CauseRule.exactlyOne => 'EXACTLY ONE',
        CauseRule.always => 'ALWAYS',
        CauseRule.never => 'NEVER',
      };

  bool predict(bool sun, bool water) => switch (this) {
        CauseRule.both => sun && water,
        CauseRule.either => sun || water,
        CauseRule.sunOnly => sun,
        CauseRule.waterOnly => water,
        CauseRule.exactlyOne => sun != water,
        CauseRule.always => true,
        CauseRule.never => false,
      };
}

class Experiment {
  const Experiment({required this.sun, required this.water});

  final bool sun;
  final bool water;

  @override
  bool operator ==(Object other) =>
      other is Experiment && sun == other.sun && water == other.water;

  @override
  int get hashCode => Object.hash(sun, water);
}

class CausalRound {
  const CausalRound({
    required this.firstModel,
    required this.secondModel,
    required this.observation,
    required this.experiments,
  });

  final CauseRule firstModel;
  final CauseRule secondModel;
  final Experiment observation;
  final List<Experiment> experiments;

  bool get observedGrowth => firstModel.predict(observation.sun, observation.water);

  bool isInformative(Experiment experiment) =>
      firstModel.predict(experiment.sun, experiment.water) !=
      secondModel.predict(experiment.sun, experiment.water);
}

/// Choose interventions that distinguish two explanations for plant growth.
class CausalLabSession {
  CausalLabSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final count = 5 + (max(0, level - 1) ~/ 4).clamp(0, 2).toInt();
    rounds = List<CausalRound>.unmodifiable(
      List.generate(count, (_) => _makeRound(random)),
    );
  }

  final int seed;
  late final List<CausalRound> rounds;
  int round = 0;
  int correct = 0;

  int get roundCount => rounds.length;
  static const int passScore = 4;
  bool get finished => round >= roundCount;
  bool get passed => finished && correct >= passScore;
  CausalRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  /// A valid experiment advances once. Invalid or repeated submissions do not.
  bool answer(Experiment experiment) {
    if (finished || !current.experiments.contains(experiment)) return false;
    if (current.isInformative(experiment)) correct++;
    round++;
    return true;
  }

  static CausalRound _makeRound(Random random) {
    const experiments = [
      Experiment(sun: false, water: false),
      Experiment(sun: true, water: false),
      Experiment(sun: false, water: true),
      Experiment(sun: true, water: true),
    ];
    final observation = experiments[random.nextInt(experiments.length)];
    final compatible = <(CauseRule, CauseRule)>[];
    for (var first = 0; first < CauseRule.values.length; first++) {
      for (var second = first + 1; second < CauseRule.values.length; second++) {
        final a = CauseRule.values[first];
        final b = CauseRule.values[second];
        if (a.predict(observation.sun, observation.water) ==
            b.predict(observation.sun, observation.water)) {
          compatible.add((a, b));
        }
      }
    }
    final pair = compatible[random.nextInt(compatible.length)];
    return CausalRound(
      firstModel: pair.$1,
      secondModel: pair.$2,
      observation: observation,
      experiments: List.unmodifiable(experiments),
    );
  }
}
