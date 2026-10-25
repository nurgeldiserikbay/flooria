import 'dart:math';

class RhymeWord {
  const RhymeWord({required this.text, required this.family});

  final String text;
  final String family;

  @override
  bool operator ==(Object other) =>
      other is RhymeWord && text == other.text && family == other.family;

  @override
  int get hashCode => Object.hash(text, family);
}

class RhymeRound {
  const RhymeRound({
    required this.target,
    required this.options,
    required this.correctIndex,
  });

  final RhymeWord target;
  final List<RhymeWord> options;
  final int correctIndex;

  RhymeWord get correctWord => options[correctIndex];
}

enum RhymeAnswerResult { invalid, incorrect, correct, sessionComplete }

/// Find a word with the same ending sound. Each seeded question has exactly
/// one answer from the target's curated rhyme family.
class RhymeRallySession {
  RhymeRallySession({required this.seed, int level = 1}) {
    final random = Random(seed);
    rounds = List<RhymeRound>.unmodifiable(List.generate(
      roundCount,
      (index) => _makeRound(random, index, level),
    ));
  }

  static const int roundCount = 10;
  static const int passScore = 7;

  final int seed;
  late final List<RhymeRound> rounds;
  int round = 0;
  int correct = 0;
  int mistakes = 0;

  bool get finished => round >= roundCount;
  bool get passed => finished && correct >= passScore;
  double get progress => round / roundCount;
  RhymeRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  RhymeAnswerResult answer(int optionIndex) {
    if (finished || optionIndex < 0 || optionIndex >= current.options.length) {
      return RhymeAnswerResult.invalid;
    }
    final wasCorrect = optionIndex == current.correctIndex;
    if (wasCorrect) {
      correct++;
    } else {
      mistakes++;
    }
    round++;
    if (finished) return RhymeAnswerResult.sessionComplete;
    return wasCorrect ? RhymeAnswerResult.correct : RhymeAnswerResult.incorrect;
  }

  static RhymeRound _makeRound(Random random, int index, int level) {
    final families = _families
        .where((family) => family.difficulty <= (level >= 4 || index >= 7 ? 2 : 1))
        .toList();
    final family = families[random.nextInt(families.length)];
    final familyWords = family.words.toList()..shuffle(random);
    final target = familyWords[0];
    final correct = familyWords[1];

    final distractorFamilies = _families
        .where((candidate) => candidate.id != family.id)
        .toList()
      ..shuffle(random);
    final distractors = distractorFamilies.take(2).map((candidate) {
      final words = candidate.words.toList()..shuffle(random);
      return words.first;
    }).toList();

    final options = <RhymeWord>[correct, ...distractors]..shuffle(random);
    return RhymeRound(
      target: target,
      options: List<RhymeWord>.unmodifiable(options),
      correctIndex: options.indexOf(correct),
    );
  }
}

class _RhymeFamily {
  const _RhymeFamily(this.id, this.words, {this.difficulty = 1});

  final String id;
  final List<RhymeWord> words;
  final int difficulty;
}

const _families = <_RhymeFamily>[
  _RhymeFamily('at', [
    RhymeWord(text: 'cat', family: 'at'),
    RhymeWord(text: 'hat', family: 'at'),
    RhymeWord(text: 'bat', family: 'at'),
    RhymeWord(text: 'mat', family: 'at'),
    RhymeWord(text: 'flat', family: 'at'),
  ]),
  _RhymeFamily('un', [
    RhymeWord(text: 'sun', family: 'un'),
    RhymeWord(text: 'fun', family: 'un'),
    RhymeWord(text: 'run', family: 'un'),
    RhymeWord(text: 'bun', family: 'un'),
    RhymeWord(text: 'stun', family: 'un'),
  ]),
  _RhymeFamily('ake', [
    RhymeWord(text: 'cake', family: 'ake'),
    RhymeWord(text: 'lake', family: 'ake'),
    RhymeWord(text: 'make', family: 'ake'),
    RhymeWord(text: 'wake', family: 'ake'),
    RhymeWord(text: 'snake', family: 'ake'),
  ]),
  _RhymeFamily('oon', [
    RhymeWord(text: 'moon', family: 'oon'),
    RhymeWord(text: 'spoon', family: 'oon'),
    RhymeWord(text: 'soon', family: 'oon'),
    RhymeWord(text: 'noon', family: 'oon'),
    RhymeWord(text: 'tune', family: 'oon'),
  ]),
  _RhymeFamily('ight', [
    RhymeWord(text: 'light', family: 'ight'),
    RhymeWord(text: 'night', family: 'ight'),
    RhymeWord(text: 'bright', family: 'ight'),
    RhymeWord(text: 'sight', family: 'ight'),
    RhymeWord(text: 'kite', family: 'ight'),
  ]),
  _RhymeFamily('ell', [
    RhymeWord(text: 'bell', family: 'ell'),
    RhymeWord(text: 'shell', family: 'ell'),
    RhymeWord(text: 'smell', family: 'ell'),
    RhymeWord(text: 'well', family: 'ell'),
    RhymeWord(text: 'tell', family: 'ell'),
  ]),
  _RhymeFamily('ain', [
    RhymeWord(text: 'rain', family: 'ain'),
    RhymeWord(text: 'train', family: 'ain'),
    RhymeWord(text: 'brain', family: 'ain'),
    RhymeWord(text: 'chain', family: 'ain'),
    RhymeWord(text: 'plane', family: 'ain'),
  ]),
  _RhymeFamily('ock', [
    RhymeWord(text: 'rock', family: 'ock'),
    RhymeWord(text: 'sock', family: 'ock'),
    RhymeWord(text: 'clock', family: 'ock'),
    RhymeWord(text: 'block', family: 'ock'),
    RhymeWord(text: 'shock', family: 'ock'),
  ]),
  _RhymeFamily('boat', [
    RhymeWord(text: 'boat', family: 'boat'),
    RhymeWord(text: 'coat', family: 'boat'),
    RhymeWord(text: 'goat', family: 'boat'),
    RhymeWord(text: 'float', family: 'boat'),
    RhymeWord(text: 'note', family: 'boat'),
  ]),
  _RhymeFamily('green', [
    RhymeWord(text: 'green', family: 'green'),
    RhymeWord(text: 'screen', family: 'green'),
    RhymeWord(text: 'queen', family: 'green'),
    RhymeWord(text: 'clean', family: 'green'),
    RhymeWord(text: 'dream', family: 'green'),
  ]),
  _RhymeFamily('play', [
    RhymeWord(text: 'play', family: 'play'),
    RhymeWord(text: 'day', family: 'play'),
    RhymeWord(text: 'way', family: 'play'),
    RhymeWord(text: 'stay', family: 'play'),
    RhymeWord(text: 'gray', family: 'play'),
  ]),
  _RhymeFamily('ower', [
    RhymeWord(text: 'flower', family: 'ower'),
    RhymeWord(text: 'power', family: 'ower'),
    RhymeWord(text: 'tower', family: 'ower'),
    RhymeWord(text: 'shower', family: 'ower'),
  ], difficulty: 2),
  _RhymeFamily('oney', [
    RhymeWord(text: 'honey', family: 'oney'),
    RhymeWord(text: 'money', family: 'oney'),
    RhymeWord(text: 'funny', family: 'oney'),
    RhymeWord(text: 'sunny', family: 'oney'),
  ], difficulty: 2),
  _RhymeFamily('ation', [
    RhymeWord(text: 'station', family: 'ation'),
    RhymeWord(text: 'vacation', family: 'ation'),
    RhymeWord(text: 'location', family: 'ation'),
    RhymeWord(text: 'creation', family: 'ation'),
  ], difficulty: 2),
];
