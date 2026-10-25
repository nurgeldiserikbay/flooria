import 'dart:math';

enum RelayRule { color, shape, quantity }

/// A card has three independent attributes. Values are stable indices so the
/// rules engine stays pure Dart and the view can choose its own presentation.
class RelayCard {
  const RelayCard({
    required this.color,
    required this.shape,
    required this.quantity,
  });

  final int color;
  final int shape;
  final int quantity;

  int valueFor(RelayRule rule) => switch (rule) {
        RelayRule.color => color,
        RelayRule.shape => shape,
        RelayRule.quantity => quantity,
      };

  @override
  bool operator ==(Object other) => other is RelayCard &&
      color == other.color && shape == other.shape && quantity == other.quantity;

  @override
  int get hashCode => Object.hash(color, shape, quantity);
}

class RuleRelayRound {
  const RuleRelayRound({
    required this.rule,
    required this.target,
    required this.options,
    required this.correctIndex,
  });

  final RelayRule rule;
  final RelayCard target;
  final List<RelayCard> options;
  final int correctIndex;

  RelayCard get correctCard => options[correctIndex];
}

/// Match a card to the target using the currently active rule. The rule
/// changes every three rounds, asking players to switch their sorting strategy.
class RuleRelaySession {
  RuleRelaySession({required this.seed}) {
    final random = Random(seed);
    _ruleSchedule = _makeRuleSchedule(random);
    rounds = List<RuleRelayRound>.unmodifiable(
      List.generate(roundCount, (index) => _makeRound(random, index)),
    );
  }

  static const int roundCount = 12;
  static const int roundsPerRule = 3;
  static const int passScore = 9;

  final int seed;
  late final List<RelayRule> _ruleSchedule;
  late final List<RuleRelayRound> rounds;
  int round = 0;
  int correct = 0;

  bool get finished => round >= roundCount;
  bool get passed => finished && correct >= passScore;
  double get progress => round / roundCount;
  RuleRelayRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  bool answer(int optionIndex) {
    if (finished || optionIndex < 0 || optionIndex >= current.options.length) {
      return false;
    }
    if (optionIndex == current.correctIndex) correct++;
    round++;
    return true;
  }

  RuleRelayRound _makeRound(Random random, int index) {
    final rule = _ruleSchedule[index];
    final target = _randomCard(random);
    final targetValue = target.valueFor(rule);
    final deck = _allCards();
    final matches = deck
        .where((card) => card.valueFor(rule) == targetValue && card != target)
        .toList()
      ..shuffle(random);
    final nonMatches = deck
        .where((card) => card.valueFor(rule) != targetValue)
        .toList()
      ..shuffle(random);

    final correct = matches.first;
    final options = <RelayCard>[correct, nonMatches[0], nonMatches[1]]
      ..shuffle(random);
    return RuleRelayRound(
      rule: rule,
      target: target,
      options: List<RelayCard>.unmodifiable(options),
      correctIndex: options.indexOf(correct),
    );
  }

  List<RelayRule> _makeRuleSchedule(Random random) {
    final schedule = <RelayRule>[];
    while (schedule.length < roundCount) {
      final block = RelayRule.values.toList()..shuffle(random);
      if (schedule.isNotEmpty && block.first == schedule.last) {
        final first = block.removeAt(0);
        block.insert(1, first);
      }
      schedule.addAll(List<RelayRule>.filled(roundsPerRule, block[0]));
      schedule.addAll(List<RelayRule>.filled(roundsPerRule, block[1]));
      schedule.addAll(List<RelayRule>.filled(roundsPerRule, block[2]));
    }
    return List<RelayRule>.unmodifiable(schedule.take(roundCount));
  }

  static RelayCard _randomCard(Random random) => RelayCard(
        color: random.nextInt(4),
        shape: random.nextInt(4),
        quantity: random.nextInt(3) + 1,
      );

  static List<RelayCard> _allCards() => [
        for (var color = 0; color < 4; color++)
          for (var shape = 0; shape < 4; shape++)
            for (var quantity = 1; quantity <= 3; quantity++)
              RelayCard(color: color, shape: shape, quantity: quantity),
      ];
}
