import 'dart:math';

enum SignalKind { target, distractor }

/// Go/no-go attention game: tap the star signal and withhold on the ring.
/// The seeded trial list always contains seven targets and five distractors.
class SignalGuardSession {
  SignalGuardSession({required this.seed}) {
    final sequence = <SignalKind>[
      ...List<SignalKind>.filled(7, SignalKind.target),
      ...List<SignalKind>.filled(5, SignalKind.distractor),
    ]..shuffle(Random(seed));
    _sequence = List<SignalKind>.unmodifiable(sequence);
  }

  static const int roundCount = 12;
  static const int passErrorLimit = 3;

  late final List<SignalKind> _sequence;
  int round = 0;
  int correctResponses = 0;
  int errors = 0;
  bool _resolved = false;

  bool get finished => round >= roundCount;
  bool get passed => finished && errors <= passErrorLimit;
  double get progress => round / roundCount;
  SignalKind get currentSignal =>
      _sequence[round.clamp(0, roundCount - 1).toInt()];
  List<SignalKind> get sequence => _sequence;

  /// Responds to the visible signal. Tapping a target is correct; tapping a
  /// distractor is a false alarm. A trial can be answered only once.
  bool tap() {
    if (finished || _resolved) return false;
    _resolved = true;
    if (currentSignal == SignalKind.target) {
      correctResponses++;
    } else {
      errors++;
    }
    _advance();
    return true;
  }

  /// Called when the response window closes. Withholding on a distractor is
  /// correct; failing to tap the target counts as a miss.
  bool timeout() {
    if (finished || _resolved) return false;
    _resolved = true;
    if (currentSignal == SignalKind.distractor) {
      correctResponses++;
    } else {
      errors++;
    }
    _advance();
    return true;
  }

  void _advance() {
    round++;
    _resolved = false;
  }
}
