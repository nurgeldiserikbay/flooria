import 'dart:math';

class WordForgePuzzle {
  const WordForgePuzzle({
    required this.answer,
    required this.clue,
    required this.letters,
  });

  final String answer;
  final String clue;
  final List<String> letters;
}

enum WordForgeSubmitResult {
  incomplete,
  incorrect,
  roundComplete,
  sessionComplete,
}

/// Builds three words of increasing length from seeded, shuffled letter banks.
/// Every tile belongs to the answer, so each generated puzzle is solvable.
class WordForgeSession {
  WordForgeSession({required this.seed}) {
    final random = Random(seed);
    _puzzles = List<WordForgePuzzle>.unmodifiable([
      _makePuzzle(_fiveLetterWords[random.nextInt(_fiveLetterWords.length)], random),
      _makePuzzle(_sixLetterWords[random.nextInt(_sixLetterWords.length)], random),
      _makePuzzle(_sevenLetterWords[random.nextInt(_sevenLetterWords.length)], random),
    ]);
  }

  final int seed;
  late final List<WordForgePuzzle> _puzzles;
  final List<int> _selectedIndices = <int>[];
  int round = 0;
  int mistakes = 0;
  int submissions = 0;

  int get roundCount => _puzzles.length;
  bool get finished => round >= roundCount;
  double get progress => round / roundCount;
  WordForgePuzzle get puzzle => _puzzles[finished ? roundCount - 1 : round];
  List<int> get selectedIndices => List<int>.unmodifiable(_selectedIndices);
  String get draft => _selectedIndices.map((index) => puzzle.letters[index]).join();

  bool select(int letterIndex) {
    if (finished || letterIndex < 0 || letterIndex >= puzzle.letters.length ||
        _selectedIndices.contains(letterIndex) ||
        _selectedIndices.length >= puzzle.answer.length) {
      return false;
    }
    _selectedIndices.add(letterIndex);
    return true;
  }

  bool removeLast() {
    if (finished || _selectedIndices.isEmpty) return false;
    _selectedIndices.removeLast();
    return true;
  }

  WordForgeSubmitResult submit() {
    if (finished) return WordForgeSubmitResult.sessionComplete;
    if (_selectedIndices.length != puzzle.answer.length) {
      return WordForgeSubmitResult.incomplete;
    }
    submissions++;
    if (draft != puzzle.answer) {
      mistakes++;
      return WordForgeSubmitResult.incorrect;
    }
    _selectedIndices.clear();
    round++;
    return finished
        ? WordForgeSubmitResult.sessionComplete
        : WordForgeSubmitResult.roundComplete;
  }

  static WordForgePuzzle _makePuzzle(_WordEntry entry, Random random) {
    final letters = entry.answer.split('');
    do {
      letters.shuffle(random);
    } while (letters.join() == entry.answer);
    return WordForgePuzzle(
      answer: entry.answer,
      clue: entry.clue,
      letters: List<String>.unmodifiable(letters),
    );
  }
}

class _WordEntry {
  const _WordEntry(this.answer, this.clue);
  final String answer;
  final String clue;
}

const _fiveLetterWords = <_WordEntry>[
  _WordEntry('BRAIN', 'The organ that helps you think and learn.'),
  _WordEntry('FOCUS', 'To pay close attention to one thing.'),
  _WordEntry('LOGIC', 'Clear reasoning that follows facts.'),
  _WordEntry('SHAPE', 'The outline or form of an object.'),
  _WordEntry('COLOR', 'Red, blue, and green are examples of this.'),
  _WordEntry('THINK', 'Use your mind to consider an idea.'),
];

const _sixLetterWords = <_WordEntry>[
  _WordEntry('MEMORY', 'The ability to keep and recall information.'),
  _WordEntry('PUZZLE', 'A game or problem that takes thought to solve.'),
  _WordEntry('SIGNAL', 'A sign or sound that sends a message.'),
  _WordEntry('NEURON', 'A nerve cell that carries information.'),
  _WordEntry('REASON', 'A cause, or the ability to think clearly.'),
  _WordEntry('SYMBOL', 'A mark or picture that stands for an idea.'),
];

const _sevenLetterWords = <_WordEntry>[
  _WordEntry('PATTERN', 'A design or sequence that repeats.'),
  _WordEntry('NETWORK', 'A group of connected people or things.'),
  _WordEntry('IMAGINE', 'Form a picture or idea in your mind.'),
  _WordEntry('EXPLORE', 'Travel through or learn about a place.'),
  _WordEntry('MACHINE', 'A device with parts that do useful work.'),
  _WordEntry('JOURNAL', 'A book where you write notes each day.'),
];
