import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/merge_2048.dart';

/// Describes where each existing tile moves before merge/spawn resolution.
class TileFlight {
  final int from;
  final int to;
  final int value;
  const TileFlight(this.from, this.to, this.value);
}

/// This planner is pure and can be tested independently from animation timing.
List<TileFlight> planTileFlights(List<int> before, MoveDirection direction) {
  if (before.length != 16) {
    throw ArgumentError('2048 board must contain 16 cells');
  }
  final flights = <TileFlight>[];
  for (var line = 0; line < 4; line++) {
    final positions = List<int>.generate(4, (step) {
      switch (direction) {
        case MoveDirection.left:
          return line * 4 + step;
        case MoveDirection.right:
          return line * 4 + 3 - step;
        case MoveDirection.up:
          return step * 4 + line;
        case MoveDirection.down:
          return (3 - step) * 4 + line;
      }
    });
    final occupied = positions.where((i) => before[i] > 0).toList();
    var destination = 0;
    for (var n = 0; n < occupied.length; n++) {
      final first = occupied[n];
      flights.add(TileFlight(first, positions[destination], before[first]));
      if (n + 1 < occupied.length && before[occupied[n + 1]] == before[first]) {
        final second = occupied[++n];
        flights.add(TileFlight(second, positions[destination], before[second]));
      }
      destination++;
    }
  }
  return flights;
}

/// Actual spatial tile animation; values don't simply crossfade in fixed cells.
class Sliding2048Board extends StatelessWidget {
  final List<int> cells;
  final List<int>? previous;
  final MoveDirection? direction;
  final int revision;

  const Sliding2048Board({
    super.key,
    required this.cells,
    required this.previous,
    required this.direction,
    required this.revision,
  });

  static const shades = [
    Color(0xFFF5E9D2), Color(0xFFFFE6AC), Color(0xFFFFD08C),
    Color(0xFFFFB889), Color(0xFFF6A08E), Color(0xFFC4ACE9),
    Color(0xFF9CCDEB), Color(0xFF8BDEBF), Color(0xFFFFCE68),
    Color(0xFFFBA7C1), Color(0xFFB29EEB), Color(0xFFFFA765),
  ];

  Widget _tile(int value, {bool pop = false}) {
    final exponent = value <= 0 ? 0 : (math.log(value) / math.ln2).round();
    final color = shades[(exponent - 1).clamp(0, shades.length - 1)];
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, .24)!, color],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(bottom: BorderSide(
          color: Color.lerp(color, const Color(0xFF755069), .28)!,
          width: 4)),
        boxShadow: const [BoxShadow(
          color: Color(0x1D614566), blurRadius: 4, offset: Offset(0, 3))],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Text('$value', style: TextStyle(
            fontSize: value >= 1024 ? 22 : 27,
            color: const Color(0xFF413753),
            fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animate = previous != null && direction != null;
    final flights = animate ? planTileFlights(previous!, direction!) : <TileFlight>[];
    return LayoutBuilder(builder: (context, constraints) {
      final total = constraints.maxWidth;
      const gap = 8.0;
      const inset = 10.0;
      final tileSize = (total - 2 * inset - 3 * gap) / 4;
      Offset tileOffset(int index) => Offset(
        inset + index % 4 * (tileSize + gap),
        inset + index ~/ 4 * (tileSize + gap),
      );
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD6BFAF),
          borderRadius: BorderRadius.circular(22),
          border: const Border(bottom: BorderSide(
            color: Color(0xFFB69BA6), width: 5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: TweenAnimationBuilder<double>(
            key: ValueKey<int>(revision),
            tween: Tween(begin: animate ? 0.0 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => Stack(children: [
              for (var i = 0; i < 16; i++)
                Positioned(
                  left: tileOffset(i).dx, top: tileOffset(i).dy,
                  width: tileSize, height: tileSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x6EFFFFFF),
                      borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (t < 1 && animate)
                for (final flight in flights)
                  Positioned(
                    left: tileOffset(flight.from).dx +
                      (tileOffset(flight.to).dx - tileOffset(flight.from).dx) * t,
                    top: tileOffset(flight.from).dy +
                      (tileOffset(flight.to).dy - tileOffset(flight.from).dy) * t,
                    width: tileSize, height: tileSize,
                    child: _tile(flight.value),
                  )
              else
                for (var i = 0; i < 16; i++)
                  if (cells[i] != 0)
                    Positioned(
                      left: tileOffset(i).dx, top: tileOffset(i).dy,
                      width: tileSize, height: tileSize,
                      child: _tile(cells[i]),
                    ),
            ]),
          ),
        ),
      );
    });
  }
}
