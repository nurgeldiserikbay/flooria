import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'ice_slide_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFE3EEF7),
  surface: Color(0xFFFFFFFF),
  ink: Color(0xFF1D2D4E),
  muted: Color(0xFF6A7C9E),
  accent: Color(0xFF2E5BD8),
  edge: Color(0xFF1D2D4E),
);
const _puck = Color(0xFFFF6B57);
const _ice = Color(0xFFF4F9FD);
const _iceLine = Color(0xFFDCE8F3);

Widget buildIceSlidePage(BuildContext context, GameLaunch launch) =>
    IceSlidePage(launch: launch);

class IceSlidePage extends StatefulWidget {
  const IceSlidePage({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<IceSlidePage> createState() => _IceSlidePageState();
}

class _IceSlidePageState extends State<IceSlidePage>
    with LevelFlow<IceSlidePage> {
  late IceSlideEngine _engine;
  int _lastLength = 1;
  int _bumps = 0;
  bool _swiped = false;
  Offset _drag = Offset.zero;
  final FocusNode _focus = FocusNode(debugLabel: 'ice-slide');

  @override
  GameLaunch get launch => widget.launch;

  @override
  void initState() {
    super.initState();
    resetLevel();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  void resetLevel() {
    _engine = IceSlideEngine.forLevel(level);
    _lastLength = 1;
    _bumps = 0;
  }

  void _slide(SlideDirection direction) {
    final length = _engine.slideLength(direction);
    final result = _engine.slide(direction);
    if (result == SlideResult.ignored) {
      if (!_engine.isCompleted) {
        HapticFeedback.selectionClick();
        setState(() => _bumps++);
      }
      return;
    }
    setState(() => _lastLength = max(1, length));
    if (result == SlideResult.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score,
        metrics: {'planning': _engine.planningMetric});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _undo() {
    if (_engine.undo()) {
      setState(() => _lastLength = 1);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => SlideDirection.up,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => SlideDirection.right,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => SlideDirection.down,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => SlideDirection.left,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    _slide(direction);
    return KeyEventResult.handled;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_swiped) return;
    _drag += details.delta;
    if (_drag.distance < 22) return;
    _swiped = true;
    final horizontal = _drag.dx.abs() > _drag.dy.abs();
    _slide(horizontal
        ? (_drag.dx > 0 ? SlideDirection.right : SlideDirection.left)
        : (_drag.dy > 0 ? SlideDirection.down : SlideDirection.up));
  }

  @override
  Widget build(BuildContext context) {
    final done = _engine.isCompleted;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GameScaffold(
        palette: _palette,
        title: 'Ice Slide',
        level: level,
        titleKey: const ValueKey('ice-title'),
        actions: [
          ChunkyIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            palette: _palette,
            onPressed: _engine.canUndo ? _undo : null,
          ),
          ChunkyIconButton(
            icon: Icons.restart_alt_rounded,
            tooltip: 'Restart',
            palette: _palette,
            onPressed: done ? null : replayLevel,
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text('STOP ON THE RING',
                  style: TextStyle(color: _palette.ink, fontSize: 13,
                    fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
              StatChip(label: 'MOVES', value: '${_engine.moves}',
                valueKey: const ValueKey('ice-moves'), palette: _palette),
              const SizedBox(width: 6),
              StatChip(label: 'BEST', value: '${_engine.par}',
                palette: _palette),
            ]),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final side = min(box.maxWidth, box.maxHeight - 12)
                    .clamp(200.0, 460.0).toDouble();
                return Center(
                  child: GestureDetector(
                    key: const ValueKey('ice-board'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) {
                      _swiped = false;
                      _drag = Offset.zero;
                    },
                    onPanUpdate: done ? null : _onPanUpdate,
                    child: _Board(engine: _engine, side: side,
                      lastLength: _lastLength, bumps: _bumps),
                  ),
                );
              }),
            ),
            AnimatedSwitcher(
              duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                  ? Duration.zero : const Duration(milliseconds: 220),
              child: done
                  ? LevelResultPanel(
                      palette: _palette,
                      launch: launch,
                      level: level,
                      stars: _engine.stars,
                      detail: '${_engine.moves} moves · best route ${_engine.par}',
                      onNext: nextLevel,
                      onReplay: replayLevel,
                    )
                  : _ArrowPad(onSlide: _slide),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.engine, required this.side,
    required this.lastLength, required this.bumps});

  final IceSlideEngine engine;
  final double side;
  final int lastLength;
  final int bumps;

  @override
  Widget build(BuildContext context) {
    const pad = 6.0;
    final cell = (side - pad * 2) / engine.size;
    Offset origin(int index) =>
        Offset(pad + (index % engine.size) * cell, pad + (index ~/ engine.size) * cell);
    final puck = origin(engine.position);
    final goal = origin(engine.goal);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ice, Color(0xFFE9F4FC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC3D9EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261D2D4E),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _IcePainter(engine: engine, cell: cell, pad: pad),
          ),
        ),
        Positioned(
          left: goal.dx,
          top: goal.dy,
          width: cell,
          height: cell,
          child: _GoalRing(done: engine.isCompleted),
        ),
        AnimatedPositioned(
          duration: reduceMotion ? Duration.zero
              : Duration(milliseconds: 60 + lastLength * 55),
          curve: Curves.easeOutCubic,
          left: puck.dx,
          top: puck.dy,
          width: cell,
          height: cell,
          child: Shake(
            trigger: bumps,
            child: Padding(
              padding: EdgeInsets.all(cell * .16),
              child: Semantics(
                label: 'Ice puck at row ${engine.position ~/ engine.size + 1}, '
                    'column ${engine.position % engine.size + 1}',
                child: Container(
                  key: const ValueKey('ice-puck'),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFA78D), _puck],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE45443),
                      width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4AFF6B57),
                        blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                child: Center(
                  child: Container(
                    width: cell * .16,
                    height: cell * .16,
                    decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: AnimatedContainer(
      duration: MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero : const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? _palette.success.withValues(alpha: .2) : Colors.transparent,
        border: Border.all(
          color: done ? _palette.success : _palette.accent, width: 3),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: .42,
          heightFactor: .42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? _palette.success : _palette.accent, width: 2),
            ),
          ),
        ),
      ),
    ),
  );
}

class _IcePainter extends CustomPainter {
  const _IcePainter({required this.engine, required this.cell,
    required this.pad});

  final IceSlideEngine engine;
  final double cell;
  final double pad;

  Offset _center(int index) => Offset(
    pad + (index % engine.size + .5) * cell,
    pad + (index ~/ engine.size + .5) * cell,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _iceLine
      ..strokeWidth = 1;
    for (var i = 1; i < engine.size; i++) {
      final d = pad + i * cell;
      canvas.drawLine(Offset(d, pad), Offset(d, size.height - pad), grid);
      canvas.drawLine(Offset(pad, d), Offset(size.width - pad, d), grid);
    }

    final trail = engine.trail;
    if (trail.length > 1) {
      final path = Path()..moveTo(_center(trail.first).dx, _center(trail.first).dy);
      for (final stop in trail.skip(1)) {
        path.lineTo(_center(stop).dx, _center(stop).dy);
      }
      canvas.drawPath(path, Paint()
        ..color = _puck.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3, cell * .1)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round);
      for (final stop in trail.take(trail.length - 1)) {
        canvas.drawCircle(_center(stop), cell * .07,
          Paint()..color = _puck.withValues(alpha: .45));
      }
    }

    final start = _center(engine.start);
    canvas.drawCircle(start, cell * .12, Paint()
      ..color = _palette.muted.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    final blockFill = Paint()..color = const Color(0xFF2B416F);
    final blockTop = Paint()..color = const Color(0xFF3F5A92);
    for (final block in engine.blocks) {
      final rect = Rect.fromLTWH(
        pad + (block % engine.size) * cell + 2,
        pad + (block ~/ engine.size) * cell + 2,
        cell - 4, cell - 4);
      final radius = Radius.circular(cell * .14);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), blockFill);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * .72),
        radius), blockTop);
    }
  }

  @override
  bool shouldRepaint(_IcePainter old) => true;
}

class _ArrowPad extends StatelessWidget {
  const _ArrowPad({required this.onSlide});
  final ValueChanged<SlideDirection> onSlide;

  @override
  Widget build(BuildContext context) {
    Widget arrow(SlideDirection direction, IconData icon) => Expanded(
      child: SizedBox(
        height: 54,
        child: ChunkyButton(
          key: ValueKey('ice-arrow-${direction.name}'),
          onPressed: () => onSlide(direction),
          color: _palette.surface,
          edgeColor: _palette.edge,
          padding: EdgeInsets.zero,
          semanticLabel: 'Slide ${direction.name}',
          child: Icon(icon, color: _palette.ink, size: 26),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        arrow(SlideDirection.left, Icons.arrow_back_rounded),
        const SizedBox(width: 8),
        arrow(SlideDirection.up, Icons.arrow_upward_rounded),
        const SizedBox(width: 8),
        arrow(SlideDirection.down, Icons.arrow_downward_rounded),
        const SizedBox(width: 8),
        arrow(SlideDirection.right, Icons.arrow_forward_rounded),
      ]),
    );
  }
}
