import 'dart:math';

enum LockMove { entered, submitted, solved, failed, ignored }

class LockClue {
  const LockClue(this.guess, this.exact, this.misplaced);
  final List<int> guess;
  final int exact;
  final int misplaced;
}

/// Deduce a hidden number code from exact-position and misplaced-digit clues.
class CombinationLockEngine {
  CombinationLockEngine._(this.level, this._code, this.maxAttempts)
      : input = List<int?>.filled(_code.length, null);

  final int level;
  final List<int> _code;
  final int maxAttempts;
  final List<int?> input;
  final List<LockClue> clues = [];
  int activeSlot = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get codeLength => _code.length;
  int get attemptsLeft => maxAttempts - clues.length;
  int get score => max(100, 1000 - clues.length * 90).toInt();

  factory CombinationLockEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 17959 + 67);
    final length = min(5, 3 + (safe - 1) ~/ 18).toInt();
    final digits = [for (var digit = 0; digit < 10; digit++) digit]..shuffle(random);
    return CombinationLockEngine._(safe, digits.take(length).toList(),
      max(7, 10 - (safe - 1) ~/ 12).toInt());
  }

  bool selectSlot(int slot) {
    if (isCompleted || isFailed || slot < 0 || slot >= codeLength) return false;
    activeSlot = slot;
    return true;
  }

  LockMove enterDigit(int digit) {
    if (isCompleted || isFailed || digit < 0 || digit > 9) return LockMove.ignored;
    for (var i = 0; i < input.length; i++) {
      if (i != activeSlot && input[i] == digit) return LockMove.ignored;
    }
    input[activeSlot] = digit;
    final nextEmpty = input.indexWhere((value) => value == null);
    activeSlot = nextEmpty < 0 ? (activeSlot + 1) % codeLength : nextEmpty;
    return LockMove.entered;
  }

  bool clearActive() {
    if (isCompleted || isFailed) return false;
    input[activeSlot] = null;
    return true;
  }

  LockMove submit() {
    if (isCompleted || isFailed || input.any((digit) => digit == null)) return LockMove.ignored;
    final guess = input.cast<int>();
    var exact = 0;
    var misplaced = 0;
    for (var i = 0; i < codeLength; i++) {
      if (guess[i] == _code[i]) {
        exact++;
      } else if (_code.contains(guess[i])) {
        misplaced++;
      }
    }
    clues.add(LockClue(List<int>.of(guess), exact, misplaced));
    if (exact == codeLength) {
      isCompleted = true;
      return LockMove.solved;
    }
    if (clues.length >= maxAttempts) {
      isFailed = true;
      return LockMove.failed;
    }
    for (var i = 0; i < input.length; i++) { input[i] = null; }
    activeSlot = 0;
    return LockMove.submitted;
  }
}
