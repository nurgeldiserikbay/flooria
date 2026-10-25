import 'dart:math';

/// Four switches feed three visible Boolean circuits. No Flutter dependency.
enum GateKind { and, or, xor, nand, nor, xnor }

class GateRule {
  const GateRule(this.kind, this.first, this.second, this.invert);
  final GateKind kind;
  final int first;
  final int second;
  final bool invert;

  bool evaluate(List<bool> inputs) {
    final a = inputs[first], b = inputs[second];
    final result = switch (kind) {
      GateKind.and => a && b,
      GateKind.or => a || b,
      GateKind.xor => a != b,
      GateKind.nand => !(a && b),
      GateKind.nor => !(a || b),
      GateKind.xnor => a == b,
    };
    return invert ? !result : result;
  }
}

class LogicGatesSession {
  LogicGatesSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _startRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int moves = 0;
  int checks = 0;
  int mistakes = 0;
  int totalMoves = 0;
  final List<bool> switches = [false, false, false, false];
  late List<GateRule> rules;
  late List<bool> target;
  late List<bool> witness;

  bool get complete => round >= roundCount;
  List<bool> get outputs => [for (final gate in rules) gate.evaluate(switches)];
  bool get matched => !complete && _same(outputs, target);

  static bool _same(List<bool> a, List<bool> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => i).every((i) => a[i] == b[i]);

  List<bool> evaluate(List<bool> inputs) {
    if (inputs.length != 4) throw ArgumentError('Exactly four inputs required');
    return [for (final gate in rules) gate.evaluate(inputs)];
  }

  void _startRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 8191) & 0x7fffffff);
    // Pick gates with pairwise overlapping inputs to encourage prediction.
    final pairs = [(0, 1), (1, 2), (2, 3)];
    rules = [
      for (final pair in pairs)
        GateRule(
          GateKind.values[random.nextInt(GateKind.values.length)],
          pair.$1,
          pair.$2,
          round == 2 && random.nextBool(),
        ),
    ];
    // Choose a reachable target by evaluating an actual switch assignment.
    // Never choose the initial all-off output; the player must interact.
    final initial = evaluate(List<bool>.filled(4, false));
    late List<bool> candidate;
    var found = false;
    for (var code = 1; code < 16; code++) {
      final mask = (code + seed.abs() + round * 3) % 15 + 1;
      candidate = [for (var bit = 0; bit < 4; bit++) (mask & (1 << bit)) != 0];
      if (!_same(evaluate(candidate), initial)) {
        found = true;
        break;
      }
    }
    if (!found) throw StateError('Unreachable target selection');
    witness = candidate;
    target = evaluate(candidate);
    for (var i = 0; i < switches.length; i++) {
      switches[i] = false;
    }
    moves = 0;
  }

  bool toggle(int index) {
    if (complete || index < 0 || index >= switches.length) return false;
    switches[index] = !switches[index];
    moves++;
    totalMoves++;
    return true;
  }

  /// Require an explicit check, so completion cannot be accidentally earned.
  bool check() {
    if (complete) return false;
    checks++;
    if (!matched) {
      mistakes++;
      return false;
    }
    round++;
    _startRound();
    return true;
  }
}
