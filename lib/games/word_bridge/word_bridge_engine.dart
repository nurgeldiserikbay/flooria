import 'dart:math';

class WordBridgeQuestion {
  const WordBridgeQuestion({
    required this.firstWord,
    required this.relatedWord,
    required this.bridgeWord,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
  });

  /// The complete first pair: [firstWord] relates to [relatedWord].
  final String firstWord;
  final String relatedWord;

  /// The first word of the pair to complete.
  final String bridgeWord;
  final List<String> options;
  final int correctIndex;
  final int difficulty;

  String get answer => options[correctIndex];
}

/// Transfer a word relationship from one pair to another.
class WordBridgeSession {
  WordBridgeSession({required this.seed}) {
    final random = Random((seed * 65537 + 49979687) & 0x7fffffff);
    final selected = <_QuestionSpec>[];
    for (final tier in const <(int, int)>[(1, 3), (2, 4), (3, 3)]) {
      final bank = _questionBank.where((question) => question.difficulty == tier.$1).toList()
        ..shuffle(random);
      selected.addAll(bank.take(tier.$2));
    }
    rounds = List<WordBridgeQuestion>.unmodifiable(selected.map((spec) {
      final options = spec.options.toList()..shuffle(random);
      return WordBridgeQuestion(
        firstWord: spec.firstWord,
        relatedWord: spec.relatedWord,
        bridgeWord: spec.bridgeWord,
        options: List<String>.unmodifiable(options),
        correctIndex: options.indexOf(spec.answer),
        difficulty: spec.difficulty,
      );
    }));
  }

  static const int roundCount = 10;
  static const int passScore = 7;

  final int seed;
  late final List<WordBridgeQuestion> rounds;
  int round = 0;
  int correct = 0;
  int mistakes = 0;

  bool get finished => round >= roundCount;
  bool get passed => finished && correct >= passScore;
  WordBridgeQuestion get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  /// Accept one visible answer and move to the next analogy.
  bool answer(int optionIndex) {
    if (finished || optionIndex < 0 || optionIndex >= current.options.length) {
      return false;
    }
    if (optionIndex == current.correctIndex) {
      correct++;
    } else {
      mistakes++;
    }
    round++;
    return true;
  }

  static const List<_QuestionSpec> _questionBank = [
    _QuestionSpec('bird', 'nest', 'bee', 'hive', ['honey', 'hive', 'web'], 1),
    _QuestionSpec('cow', 'calf', 'horse', 'foal', ['stable', 'foal', 'hoof'], 1),
    _QuestionSpec('hot', 'cold', 'wide', 'narrow', ['long', 'narrow', 'deep'], 1),
    _QuestionSpec('page', 'book', 'petal', 'flower', ['flower', 'leaf', 'stem'], 1),
    _QuestionSpec('eye', 'see', 'nose', 'smell', ['sneeze', 'smell', 'breathe'], 1),
    _QuestionSpec('dog', 'bark', 'cat', 'meow', ['neigh', 'meow', 'chirp'], 1),
    _QuestionSpec('breakfast', 'morning', 'dinner', 'evening', ['evening', 'plate', 'kitchen'], 1),
    _QuestionSpec('chef', 'kitchen', 'pilot', 'cockpit', ['runway', 'cockpit', 'airport'], 2),
    _QuestionSpec('key', 'unlock', 'soap', 'clean', ['clean', 'bubble', 'scent'], 2),
    _QuestionSpec('thermometer', 'temperature', 'scale', 'weight', ['weight', 'length', 'height'], 2),
    _QuestionSpec('silkworm', 'silk', 'sheep', 'wool', ['wool', 'hoof', 'lamb'], 2),
    _QuestionSpec('book', 'shelf', 'car', 'garage', ['wheel', 'garage', 'road'], 2),
    _QuestionSpec('circle', 'sphere', 'square', 'cube', ['cube', 'rectangle', 'pyramid'], 2),
    _QuestionSpec('clock', 'time', 'compass', 'direction', ['map', 'direction', 'north'], 2),
    _QuestionSpec('author', 'book', 'composer', 'song', ['stage', 'song', 'instrument'], 3),
    _QuestionSpec('desert', 'cactus', 'arctic', 'seal', ['ice', 'seal', 'igloo'], 3),
    _QuestionSpec('minute', 'hour', 'centimeter', 'meter', ['ruler', 'meter', 'distance'], 3),
    _QuestionSpec('seed', 'plant', 'egg', 'chick', ['shell', 'nest', 'chick'], 3),
    _QuestionSpec('whisper', 'quiet', 'shout', 'loud', ['loud', 'angry', 'voice'], 3),
    _QuestionSpec('brick', 'wall', 'thread', 'fabric', ['needle', 'fabric', 'cotton'], 3),
    _QuestionSpec('France', 'Paris', 'Japan', 'Tokyo', ['Tokyo', 'Seoul', 'Asia'], 3),
  ];
}

class _QuestionSpec {
  const _QuestionSpec(
    this.firstWord,
    this.relatedWord,
    this.bridgeWord,
    this.answer,
    this.options,
    this.difficulty,
  );

  final String firstWord;
  final String relatedWord;
  final String bridgeWord;
  final String answer;
  final List<String> options;
  final int difficulty;
}
