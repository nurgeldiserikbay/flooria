import 'dart:math';

enum HueSwapResult { ignored, swapped, completed }

enum HueAnchors { checker, border, sides, corners }

/// Restore a two-dimensional colour gradient by swapping tiles. Anchored
/// tiles never move and give the player fixed reference points.
class HueSortEngine {
  HueSortEngine._({
    required this.level,
    required this.columns,
    required this.rows,
    required this.anchors,
    required List<int> colors,
    required Set<int> fixed,
    required List<int> tiles,
  })  : colors = List<int>.unmodifiable(colors),
        fixed = Set<int>.unmodifiable(fixed),
        _tiles = tiles,
        minSwaps = _minimumSwaps(tiles);

  final int level;
  final int columns;
  final int rows;
  final HueAnchors anchors;

  /// ARGB colour of each tile id. Tile id equals its solved position.
  final List<int> colors;
  final Set<int> fixed;
  final List<int> _tiles;
  final int minSwaps;
  int swaps = 0;
  bool _completed = false;

  int get cellCount => columns * rows;
  bool get isCompleted => _completed;
  int tileAt(int position) => _tiles[position];
  List<int> get tiles => List<int>.unmodifiable(_tiles);
  bool isFixed(int position) => fixed.contains(position);
  int get misplaced => [for (var i = 0; i < cellCount; i++) if (_tiles[i] != i) i].length;

  int get stars => swaps <= (minSwaps * 1.15).ceil()
      ? 3 : swaps <= (minSwaps * 1.5).ceil() ? 2 : 1;
  int get score => max(100, 1000 - max(0, swaps - minSwaps) * 20).toInt();
  int get perceptionMetric =>
      (100 - max(0, swaps - minSwaps) * 3).clamp(30, 100).toInt();

  static ({int columns, int rows, HueAnchors anchors, double spread})
      layoutForLevel(int level) {
    if (level <= 2) return (columns: 4, rows: 5, anchors: HueAnchors.checker, spread: 1);
    if (level <= 4) return (columns: 4, rows: 6, anchors: HueAnchors.checker, spread: 1);
    if (level <= 14) {
      return (columns: 5, rows: 7, anchors: HueAnchors.border,
        spread: 1 - (level - 5) * .02);
    }
    if (level <= 29) {
      return (columns: 5, rows: 7, anchors: HueAnchors.sides,
        spread: .9 - (level - 15) * .01);
    }
    if (level <= 49) {
      return (columns: 5, rows: 7, anchors: HueAnchors.corners,
        spread: .85 - (level - 30) * .008);
    }
    return (columns: 6, rows: 8, anchors: HueAnchors.corners,
      spread: max(.55, .75 - (level - 50) * .004));
  }

  factory HueSortEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final layout = layoutForLevel(safeLevel);
    final columns = layout.columns;
    final rows = layout.rows;
    final random = Random(seed ?? safeLevel * 4099 + 17);
    final colors = _gradient(columns, rows, layout.spread, random);
    final fixed = <int>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final corner = (r == 0 || r == rows - 1) && (c == 0 || c == columns - 1);
        final keep = switch (layout.anchors) {
          HueAnchors.checker => (r + c).isEven,
          HueAnchors.border => r == 0 || c == 0 || r == rows - 1 || c == columns - 1,
          HueAnchors.sides => c == 0 || c == columns - 1,
          HueAnchors.corners => corner,
        };
        if (keep || corner) fixed.add(r * columns + c);
      }
    }

    final movable = [for (var i = 0; i < columns * rows; i++) if (!fixed.contains(i)) i];
    final tiles = List<int>.generate(columns * rows, (i) => i);
    // Shuffle movable tiles until most of them are out of place.
    for (var attempt = 0; attempt < 20; attempt++) {
      final shuffled = [...movable]..shuffle(random);
      for (var i = 0; i < movable.length; i++) {
        tiles[movable[i]] = shuffled[i];
      }
      final wrong = movable.where((p) => tiles[p] != p).length;
      if (wrong >= (movable.length * .75).ceil()) break;
    }
    if (movable.length >= 2 && movable.every((p) => tiles[p] == p)) {
      final a = movable[0];
      final b = movable[1];
      tiles[a] = b;
      tiles[b] = a;
    }
    return HueSortEngine._(level: safeLevel, columns: columns, rows: rows,
      anchors: layout.anchors, colors: colors, fixed: fixed, tiles: tiles);
  }

  static int _minimumSwaps(List<int> tiles) {
    final seen = List<bool>.filled(tiles.length, false);
    var swaps = 0;
    for (var i = 0; i < tiles.length; i++) {
      if (seen[i] || tiles[i] == i) continue;
      var length = 0;
      var j = i;
      while (!seen[j]) {
        seen[j] = true;
        j = tiles[j];
        length++;
      }
      swaps += length - 1;
    }
    return swaps;
  }

  HueSwapResult swap(int a, int b) {
    if (_completed || a == b || a < 0 || b < 0 ||
        a >= cellCount || b >= cellCount || isFixed(a) || isFixed(b)) {
      return HueSwapResult.ignored;
    }
    final tile = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = tile;
    swaps++;
    for (var i = 0; i < cellCount; i++) {
      if (_tiles[i] != i) return HueSwapResult.swapped;
    }
    _completed = true;
    return HueSwapResult.completed;
  }

  /// Lightness and chroma blend between four corners while the hue drifts
  /// along both axes, so the middle of the board stays as vivid as its
  /// edges. [spread] narrows the hue range on later levels.
  static List<int> _gradient(int columns, int rows, double spread,
      Random random) {
    final hue = random.nextDouble() * 360;
    final turn = random.nextBool() ? 1 : -1;
    final hueAcross = turn * 75 * spread;
    final hueDown = turn * 120 * spread;
    const lightness = [.88, .74, .66, .47];
    const chroma = [.09, .15, .14, .12];
    double blend(List<double> corners, double u, double v) =>
        corners[0] * (1 - u) * (1 - v) + corners[1] * u * (1 - v) +
        corners[2] * (1 - u) * v + corners[3] * u * v;

    final result = <int>[];
    for (var r = 0; r < rows; r++) {
      final v = r / (rows - 1);
      for (var c = 0; c < columns; c++) {
        final u = c / (columns - 1);
        result.add(_oklchToArgb(blend(lightness, u, v), blend(chroma, u, v),
          hue + hueAcross * u + hueDown * v));
      }
    }
    return result;
  }

  /// Converts OKLCH to sRGB, lowering chroma until the colour is in gamut
  /// instead of clipping channels (clipping shifts the hue).
  static int _oklchToArgb(double lightness, double chroma, double hueDegrees) {
    final h = hueDegrees * pi / 180;
    var c = chroma;
    late List<double> linear;
    while (true) {
      final a = c * cos(h);
      final b = c * sin(h);
      final l_ = lightness + .3963377774 * a + .2158037573 * b;
      final m_ = lightness - .1055613458 * a - .0638541728 * b;
      final s_ = lightness - .0894841775 * a - 1.2914855480 * b;
      final l = l_ * l_ * l_;
      final m = m_ * m_ * m_;
      final s = s_ * s_ * s_;
      linear = [
        4.0767416621 * l - 3.3077115913 * m + .2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - .3413193965 * s,
        -.0041960863 * l - .7034186147 * m + 1.7076147010 * s,
      ];
      if (c <= 0 || linear.every((v) => v >= -.0005 && v <= 1.0005)) break;
      c -= .005;
    }
    int channel(double value) {
      final v = value.clamp(0.0, 1.0);
      final srgb = v <= .0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - .055;
      return (srgb * 255).round().clamp(0, 255);
    }
    return 0xFF000000 |
        channel(linear[0]) << 16 |
        channel(linear[1]) << 8 |
        channel(linear[2]);
  }
}
