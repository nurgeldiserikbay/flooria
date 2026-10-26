import 'dart:math';

enum WordLadderAnswer { invalid, correct, incorrect, complete }

class WordLadderPrompt {
  const WordLadderPrompt({
    required this.currentWord,
    required this.targetWord,
    required this.rung,
    required this.rungCount,
    required this.choices,
    required this.correctWord,
  });

  final String currentWord;
  final String targetWord;
  final int rung;
  final int rungCount;
  final List<String> choices;
  final String correctWord;
}

class _Ladder {
  const _Ladder(this.words);
  final List<String> words;
}

/// Pure Dart rules for a seeded word transformation game.
class WordLadderSession {
  WordLadderSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final maxRungs = level < 4 ? 2 : (level < 9 ? 3 : 5);
    final eligible = _ladders
        .where((ladder) => ladder.words.length - 1 <= maxRungs)
        .toList();
    rounds = List<WordLadderRound>.unmodifiable(
      List.generate(
        roundCount,
        (_) => _makeRound(eligible[random.nextInt(eligible.length)], random),
      ),
    );
  }

  static const int roundCount = 6;
  static const int passScore = 4;

  static const _ladders = <_Ladder>[
    _Ladder(['cat', 'cot', 'dot']),
    _Ladder(['hit', 'hot', 'dot']),
    _Ladder(['cat', 'bat', 'bag', 'bog']),
    _Ladder(['lead', 'load', 'goad', 'gold']),
    _Ladder(['coat', 'boat', 'bolt', 'belt']),
    _Ladder(['cold', 'cord', 'card', 'ward', 'warm']),
    _Ladder(['head', 'heal', 'teal', 'tell', 'tall', 'tail']),
  ];

  static const _decoys = <String>[
    'cap', 'can', 'cab', 'car', 'cut', 'cup', 'bat', 'hat', 'mat', 'rat',
    'hot', 'got', 'lot', 'pot', 'cop', 'con', 'cog', 'dog', 'log', 'fog',
    'sit', 'bit', 'fit', 'hit', 'cot', 'dot', 'don', 'cat', 'bag', 'bog',
    'tag', 'rag', 'sag', 'wag', 'gag', 'mag', 'bug', 'big', 'beg',
    'bold', 'gold', 'hold', 'sold', 'told', 'colt', 'cord', 'card', 'lord',
    'ford', 'word', 'core', 'cork', 'hard', 'care', 'cart', 'ware', 'wart',
    'warn', 'wade', 'bead', 'head', 'leaf', 'lean', 'lend', 'read', 'road',
    'loan', 'loaf', 'goal', 'good', 'heat', 'hear', 'held', 'heed', 'deal',
    'meal', 'real', 'heap', 'team', 'tear', 'bell', 'fell', 'sell', 'till',
    'wall', 'fall', 'call', 'tale', 'talk', 'goat', 'cost', 'coal', 'boar',
    'boot', 'molt', 'bold', 'belt',
  ];

  final int seed;
  late final List<WordLadderRound> rounds;
  int roundIndex = 0;
  int rungIndex = 0;
  int solved = 0;
  int mistakes = 0;

  bool get finished => roundIndex >= roundCount;
  bool get passed => finished && solved >= passScore;
  double get progress => roundIndex / roundCount;
  WordLadderRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];
  WordLadderPrompt get prompt => current.prompts[rungIndex];

  WordLadderAnswer answer(String word) {
    if (finished || !prompt.choices.contains(word)) {
      return WordLadderAnswer.invalid;
    }

    if (word != prompt.correctWord) {
      mistakes++;
      roundIndex++;
      rungIndex = 0;
      return finished ? WordLadderAnswer.complete : WordLadderAnswer.incorrect;
    }

    rungIndex++;
    if (rungIndex == current.prompts.length) {
      solved++;
      roundIndex++;
      rungIndex = 0;
      return finished ? WordLadderAnswer.complete : WordLadderAnswer.correct;
    }
    return WordLadderAnswer.correct;
  }

  static WordLadderRound _makeRound(_Ladder ladder, Random random) {
    final prompts = <WordLadderPrompt>[];
    final words = ladder.words;
    for (var index = 0; index < words.length - 1; index++) {
      final current = words[index];
      final correct = words[index + 1];
      final decoys = _decoys
          .where((candidate) =>
              candidate.length == current.length &&
              candidate != correct &&
              !words.contains(candidate) &&
              _oneLetterApart(candidate, current))
          .toSet()
          .toList()
        ..shuffle(random);
      final choices = <String>[correct, ...decoys.take(3)]..shuffle(random);
      prompts.add(WordLadderPrompt(
        currentWord: current,
        targetWord: words.last,
        rung: index + 1,
        rungCount: words.length - 1,
        choices: List<String>.unmodifiable(choices),
        correctWord: correct,
      ));
    }
    return WordLadderRound(
      words: List<String>.unmodifiable(words),
      prompts: List<WordLadderPrompt>.unmodifiable(prompts),
    );
  }

  static bool _oneLetterApart(String a, String b) {
    if (a.length != b.length) return false;
    var differences = 0;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) differences++;
      if (differences > 1) return false;
    }
    return differences == 1;
  }
}

class WordLadderRound {
  const WordLadderRound({required this.words, required this.prompts});

  final List<String> words;
  final List<WordLadderPrompt> prompts;
}
