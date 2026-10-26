import 'dart:math';

enum BeliefPlace { garden, kitchen, bedroom, playroom }

enum BeliefAnswerResult { invalid, incorrect, correct, complete }

class BeliefMove {
  const BeliefMove({
    required this.from,
    required this.to,
    required this.characterSaw,
  });

  final BeliefPlace from;
  final BeliefPlace to;
  final bool characterSaw;
}

/// A seeded social-perspective puzzle. Follow what one character witnessed to
/// infer where they believe a hidden object is.
class BeliefRound {
  const BeliefRound({
    required this.character,
    required this.objectName,
    required this.initialPlace,
    required this.moves,
    required this.options,
    required this.correctPlace,
  });

  final String character;
  final String objectName;
  final BeliefPlace initialPlace;
  final List<BeliefMove> moves;
  final List<BeliefPlace> options;
  final BeliefPlace correctPlace;

  BeliefPlace get actualPlace =>
      moves.isEmpty ? initialPlace : moves.last.to;

  BeliefPlace get beliefPlace {
    var belief = initialPlace;
    for (final move in moves) {
      if (move.characterSaw) belief = move.to;
    }
    return belief;
  }
}

class BeliefDetectiveSession {
  BeliefDetectiveSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final complexity = level < 4 ? 2 : (level < 9 ? 3 : 4);
    rounds = List<BeliefRound>.unmodifiable(
      List.generate(roundCount, (_) => _makeRound(random, complexity)),
    );
  }

  static const int roundCount = 6;
  static const int passScore = 4;

  static const characters = ['Mia', 'Leo', 'Ava', 'Noah'];
  static const objects = ['star', 'teddy bear', 'kite', 'toy boat'];

  final int seed;
  late final List<BeliefRound> rounds;
  int roundIndex = 0;
  int correctCount = 0;
  int mistakes = 0;

  bool get finished => roundIndex >= roundCount;
  bool get passed => finished && correctCount >= passScore;
  double get progress => roundIndex / roundCount;
  BeliefRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];

  BeliefAnswerResult answer(BeliefPlace place) {
    if (finished || !current.options.contains(place)) {
      return BeliefAnswerResult.invalid;
    }

    final correct = place == current.correctPlace;
    if (correct) {
      correctCount++;
    } else {
      mistakes++;
    }
    roundIndex++;

    if (finished) return BeliefAnswerResult.complete;
    return correct
        ? BeliefAnswerResult.correct
        : BeliefAnswerResult.incorrect;
  }

  static BeliefRound _makeRound(Random random, int complexity) {
    final moveCount = complexity + random.nextInt(2);
    final initial =
        BeliefPlace.values[random.nextInt(BeliefPlace.values.length)];
    var actual = initial;
    var belief = initial;
    final hiddenMove = random.nextInt(moveCount);
    final moves = <BeliefMove>[];

    for (var index = 0; index < moveCount; index++) {
      final destinations = BeliefPlace.values
          .where((place) => place != actual)
          .toList();
      final destination = destinations[random.nextInt(destinations.length)];
      final observed = index != hiddenMove && random.nextInt(4) != 0;
      moves.add(BeliefMove(
        from: actual,
        to: destination,
        characterSaw: observed,
      ));
      actual = destination;
      if (observed) belief = destination;
    }

    final options = List<BeliefPlace>.of(BeliefPlace.values)..shuffle(random);
    return BeliefRound(
      character: characters[random.nextInt(characters.length)],
      objectName: objects[random.nextInt(objects.length)],
      initialPlace: initial,
      moves: List<BeliefMove>.unmodifiable(moves),
      options: List<BeliefPlace>.unmodifiable(options),
      correctPlace: belief,
    );
  }
}
