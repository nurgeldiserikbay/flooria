import 'dart:math';

/// Standalone visual-discrimination puzzle. All randomness is deterministic.
class ColorSpotRound {
  const ColorSpotRound({
    required this.colors,
    required this.oddIndex,
  });

  final List<int> colors; // RGB colors, opaque
  final int oddIndex;
}

class ColorSpotSession {
  ColorSpotSession({required this.seed});

  final int seed;
  static const roundCount = 5;
  int round = 0;
  int correct = 0;

  bool get finished => round >= roundCount;

  ColorSpotRound get current {
    if (finished) throw StateError('Color Spot session is finished');
    final rng = Random((seed * 1103515245 + round * 104729) & 0x7fffffff);
    const palette = <int>[
      0xFF62ABD9, 0xFFAC8DD8, 0xFFDB8CA8, 0xFF75BD9D,
      0xFFE3B265, 0xFF8C9DD8, 0xFFD99879, 0xFF75C6C4,
    ];
    final base = palette[rng.nextInt(palette.length)];
    final channel = rng.nextInt(3);
    final shift = round >= 3 ? 36 : 48;
    final rgb = base & 0xFFFFFF;
    final shiftBits = (2 - channel) * 8;
    final oldComponent = (rgb >> shiftBits) & 0xFF;
    final newComponent = oldComponent + shift <= 255
      ? oldComponent + shift : oldComponent - shift;
    final mask = 0xFF << shiftBits;
    final odd = 0xFF000000 | ((rgb & ~mask) |
      (newComponent << shiftBits));
    final index = rng.nextInt(9);
    return ColorSpotRound(
      oddIndex: index,
      colors: List<int>.generate(9, (i) => i == index ? odd : base),
    );
  }

  bool answer(int index) {
    if (finished || index < 0 || index > 8) return false;
    final hit = index == current.oddIndex;
    if (hit) correct++;
    round++;
    return hit;
  }
}
