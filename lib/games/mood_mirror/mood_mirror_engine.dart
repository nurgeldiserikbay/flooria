import 'dart:math';

enum FacialEmotion { joy, sadness, anger, surprise, calm, worry }

enum MoodResponseResult { invalid, correct, incorrect, complete }

class EmotionFaceRound {
  EmotionFaceRound({
    required this.emotion,
    required Iterable<FacialEmotion> choices,
  }) : choices = List<FacialEmotion>.unmodifiable(choices) {
    if (this.choices.length < 2 ||
        this.choices.toSet().length != this.choices.length ||
        this.choices.where((choice) => choice == emotion).length != 1) {
      throw ArgumentError('A round needs one correct, unique emotion choice.');
    }
  }

  final FacialEmotion emotion;
  final List<FacialEmotion> choices;
}

class MoodMirrorSession {
  MoodMirrorSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final choiceCount =
        (3 + ((level - 1) ~/ 4)).clamp(3, FacialEmotion.values.length).toInt();
    final emotions = List<FacialEmotion>.of(FacialEmotion.values)
      ..shuffle(random);
    rounds = List<EmotionFaceRound>.unmodifiable([
      for (final emotion in emotions)
        _makeRound(emotion, choiceCount, random),
    ]);
  }

  static const int roundCount = 6;
  static const int passScore = 5;

  final int seed;
  late final List<EmotionFaceRound> rounds;
  int roundIndex = 0;
  int correctAnswers = 0;
  int mistakes = 0;

  bool get finished => roundIndex >= roundCount;
  bool get passed => finished && correctAnswers >= passScore;
  double get progress => roundIndex / roundCount;
  EmotionFaceRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];

  MoodResponseResult respond(FacialEmotion choice) {
    if (finished || !current.choices.contains(choice)) {
      return MoodResponseResult.invalid;
    }

    if (choice == current.emotion) {
      correctAnswers++;
    } else {
      mistakes++;
    }
    roundIndex++;

    if (finished) return MoodResponseResult.complete;
    return choice == rounds[roundIndex - 1].emotion
        ? MoodResponseResult.correct
        : MoodResponseResult.incorrect;
  }

  EmotionFaceRound _makeRound(
    FacialEmotion emotion,
    int choiceCount,
    Random random,
  ) {
    final distractors =
        FacialEmotion.values.where((choice) => choice != emotion).toList()
          ..shuffle(random);
    final choices = <FacialEmotion>[
      emotion,
      ...distractors.take(choiceCount - 1),
    ]..shuffle(random);
    return EmotionFaceRound(emotion: emotion, choices: choices);
  }
}
