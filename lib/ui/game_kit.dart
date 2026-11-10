import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/game_registry.dart';

/// Per-game colour set. Each module keeps its own identity; shared controls
/// use quiet tactile depth instead of hard borders and offset slabs.
@immutable
class GamePalette {
  const GamePalette({
    required this.ground,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.edge,
    this.onAccent = Colors.white,
    this.success = const Color(0xFF2FA67A),
    this.danger = const Color(0xFFE5525F),
  });

  final Color ground;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color edge;
  final Color onAccent;
  final Color success;
  final Color danger;

  /// Darkens [color] for the solid "thickness" under a pressable.
  static Color shade(Color color, [double amount = .28]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

/// Tactile, accessible control with a soft edge that follows the finger.

class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    this.edgeColor,
    this.borderColor,
    this.depth = 4,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? edgeColor;
  final Color? borderColor;
  final double depth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final edge = widget.edgeColor ?? GamePalette.shade(widget.color);
    final travel = _down && enabled ? widget.depth : 0.0;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down && enabled ? .96 : 1,
          duration: reduceMotion
              ? Duration.zero : const Duration(milliseconds: 105),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: reduceMotion
                ? Duration.zero : const Duration(milliseconds: 150),
            opacity: enabled ? 1 : .35,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.depth),
              child: AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero : const Duration(milliseconds: 85),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, travel, 0),
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(widget.color, Colors.white, .17)!,
                      widget.color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(
                    color: widget.borderColor ??
                        edge.withValues(alpha: .30),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: edge.withValues(alpha: .22),
                      blurRadius: 3,
                      offset: Offset(0, widget.depth - travel),
                    ),
                  ],
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon version of [ChunkyButton] for toolbars.
class ChunkyIconButton extends StatelessWidget {
  const ChunkyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.palette,
    required this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final GamePalette palette;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: size,
      height: size + 3,
      child: ChunkyButton(
        onPressed: onPressed,
        color: palette.surface,
        edgeColor: palette.edge,
        depth: 3,
        radius: 14,
        padding: EdgeInsets.zero,
        semanticLabel: tooltip,
        child: Icon(icon, color: palette.ink, size: size * .48),
      ),
    ),
  );
}

/// Shared gameplay stage. Keeps controls outside the board so each module
/// can use its own interaction layout without losing a consistent identity.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.palette,
    required this.title,
    required this.level,
    required this.child,
    this.actions = const [],
    this.titleKey,
  });

  final GamePalette palette;
  final String title;
  final int level;
  final Widget child;
  final List<Widget> actions;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dark = ThemeData.estimateBrightnessForColor(palette.ground) ==
        Brightness.dark;
    return Scaffold(
      backgroundColor: palette.ground,
      body: Stack(fit: StackFit.expand, children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.ground,
                Color.lerp(palette.ground, palette.surface, dark ? .24 : .55)!,
                palette.ground,
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GameStagePainter(
                color: palette.accent.withValues(alpha: dark ? .11 : .09),
              ),
            ),
          ),
        ),
        Positioned(top: 60, right: -115,
          child: _GameOrb(size: 300, color: palette.accent)),
        Positioned(bottom: -45, left: -120,
          child: _GameOrb(size: 260, color: palette.success)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(children: [
                    Material(
                      color: palette.surface.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(17),
                      child: InkWell(
                        key: const ValueKey('game-back'),
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(17),
                        child: Tooltip(
                          message: 'Back to games',
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: palette.edge.withValues(alpha: .18),
                              ),
                            ),
                            child: Icon(Icons.arrow_back_rounded,
                              color: palette.ink, size: 23),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            key: titleKey,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.55,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: palette.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'READY TO PLAY',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: dark ? .22 : .11),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: palette.accent.withValues(alpha: .20),
                        ),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('LEVEL', style: TextStyle(
                          color: palette.muted,
                          fontSize: 9,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w800,
                        )),
                        Text('$level', style: TextStyle(
                          color: palette.ink,
                          fontSize: 19,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                      ]),
                    ),
                    for (final action in actions) ...[
                      const SizedBox(width: 6),
                      action,
                    ],
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: [
                        palette.accent.withValues(alpha: .75),
                        palette.success.withValues(alpha: .45),
                        palette.accent.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('game-stage-$title'),
                    tween: Tween<double>(begin: reducedMotion ? 1 : .97, end: 1),
                    duration: reducedMotion
                        ? Duration.zero : const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, stage) =>
                        Transform.scale(scale: scale, child: stage),
                    child: child,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Low-contrast decorative dots: drawn rather than loaded as bitmap assets.
class _GameStagePainter extends CustomPainter {
  const _GameStagePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 38.0;
    for (double y = 22; y < size.height; y += spacing) {
      final row = (y / spacing).round();
      for (double x = row.isEven ? 16 : 35;
          x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.15, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GameStagePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GameOrb extends StatelessWidget {
  const _GameOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(
      colors: [color.withValues(alpha: .14), color.withValues(alpha: 0)],
    )),
  ));
}

/// A row of discrete progress segments, one per round or target.
class SegmentBar extends StatelessWidget {
  const SegmentBar({
    super.key,
    required this.total,
    required this.done,
    required this.palette,
    this.failed = const {},
  });

  final int total;
  final int done;
  final GamePalette palette;
  final Set<int> failed;

  @override
  Widget build(BuildContext context) => Row(children: [
    for (var i = 0; i < total; i++) ...[
      if (i > 0) const SizedBox(width: 5),
      Expanded(
        child: AnimatedContainer(
          duration: MediaQuery.maybeOf(context)?.disableAnimations == true
              ? Duration.zero : const Duration(milliseconds: 220),
          height: 8,
          decoration: BoxDecoration(
            color: failed.contains(i)
                ? palette.danger
                : i < done ? palette.accent : palette.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: palette.edge.withValues(alpha: .13),
              width: 1,
            ),
          ),
        ),
      ),
    ],
  ]);
}

/// Small label + value pair used in game status rows.
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value,
    required this.palette, this.valueKey});

  final String label;
  final String value;
  final GamePalette palette;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: palette.surface.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: palette.edge.withValues(alpha: .16), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(color: palette.muted, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: .2)),
      const SizedBox(width: 6),
      Text(value, key: valueKey, style: TextStyle(color: palette.ink,
        fontSize: 15, fontWeight: FontWeight.w900,
        fontFeatures: const [FontFeature.tabularFigures()])),
    ]),
  );
}

/// One-line instruction under the board. Shrinks instead of overflowing on
/// narrow phones.
class HintLine extends StatelessWidget {
  const HintLine(this.text, {super.key, required this.palette, this.leading,
    this.height});

  final String text;
  final GamePalette palette;
  final Widget? leading;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(text, style: TextStyle(color: palette.muted, fontSize: 12.5,
              fontWeight: FontWeight.w700, letterSpacing: .15)),
          ]),
        ),
      ),
    ),
  );
}

/// Right-aligned group of [StatChip]s that scales down when space is tight.
class StatGroup extends StatelessWidget {
  const StatGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          children[i],
        ],
      ]),
    ),
  );
}

/// End-of-level panel. Map nodes return to the map; standalone play moves on.
class LevelResultPanel extends StatelessWidget {
  const LevelResultPanel({
    super.key,
    required this.palette,
    required this.launch,
    required this.level,
    required this.stars,
    required this.detail,
    required this.onNext,
    required this.onReplay,
  });

  final GamePalette palette;
  final GameLaunch launch;
  final int level;
  final int stars;
  final String detail;
  final VoidCallback onNext;
  final VoidCallback onReplay;

  String get _primaryLabel {
    if (launch.mode == GamePlayMode.neuron) {
      return level >= launch.maxLevel ? 'BACK TO MAP' : 'NEXT LEVEL';
    }
    return level >= launch.maxLevel ? 'FINISH' : 'NEXT LEVEL';
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      if (MediaQuery.maybeOf(context)?.disableAnimations != true)
        Positioned(
          top: -34,
          left: 0,
          right: 0,
          height: 64,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              key: const ValueKey('level-confetti'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 820),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => CustomPaint(
                painter: _CelebrationPainter(progress),
              ),
            ),
          ),
        ),
      _PanelShell(
        palette: palette,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _PopIn(
              delay: Duration(milliseconds: 120 + i * 110),
              child: Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey('result-star-$i-${i < stars}'),
                size: i == 1 ? 38 : 30,
                color: i < stars ? const Color(0xFFF5B83D) : palette.muted,
              ),
            ),
          ),
      ]),
      const SizedBox(height: 4),
      Text('LEVEL CLEAR', key: const ValueKey('level-clear'),
        style: TextStyle(color: palette.ink, fontSize: 17,
          fontWeight: FontWeight.w900, letterSpacing: 1.4)),
      const SizedBox(height: 3),
      Text(detail, textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 12,
          fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        SizedBox(
          width: 54,
          height: 54,
          child: ChunkyButton(
            onPressed: onReplay,
            color: palette.surface,
            edgeColor: palette.edge,
            padding: EdgeInsets.zero,
            semanticLabel: 'Replay',
            child: Icon(Icons.replay_rounded, color: palette.ink),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 54,
            child: ChunkyButton(
              onPressed: onNext,
              color: palette.accent,
              padding: EdgeInsets.zero,
              child: Text(_primaryLabel, style: TextStyle(
                color: palette.onAccent, fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
            ),
          ),
        ),
      ]),
        ]),
      ),
    ],
  );
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter(this.progress);
  final double progress;

  static const _colors = [
    Color(0xFFFFC857), Color(0xFFFF8D78), Color(0xFF63CDB0),
    Color(0xFF7E9EFF), Color(0xFFC28BF3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1 - progress * .8).clamp(0.0, 1.0).toDouble();
    final origin = Offset(size.width / 2, size.height * .86);
    for (var i = 0; i < 18; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final spread = (i ~/ 2 + 1) / 9;
      final dx = side * (8 + size.width * .42 * spread) * progress;
      final dy = -(12 + (i % 5) * 8) * progress;
      final center = origin + Offset(dx, dy);
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: opacity);
      if (i % 3 == 0) {
        canvas.drawCircle(center, 2.4 + (i % 2), paint);
      } else {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate((i - 8) * .19 * progress);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 4, height: 8),
          const Radius.circular(1.5)), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Shown when a level can be failed; the player retries the same level.
class RetryPanel extends StatelessWidget {
  const RetryPanel({super.key, required this.palette, required this.title,
    required this.detail, required this.onRetry});

  final GamePalette palette;
  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _PanelShell(
    palette: palette,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, key: const ValueKey('level-retry'),
        style: TextStyle(color: palette.ink, fontSize: 17,
          fontWeight: FontWeight.w900, letterSpacing: 1.4)),
      const SizedBox(height: 3),
      Text(detail, textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 12,
          fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ChunkyButton(
          onPressed: onRetry,
          color: palette.accent,
          padding: EdgeInsets.zero,
          child: Text('TRY AGAIN', style: TextStyle(color: palette.onAccent,
            fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ),
      ),
    ]),
  );
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.palette, required this.child});
  final GamePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero : const Duration(milliseconds: 260),
    curve: Curves.easeOutBack,
    builder: (context, t, child) => Transform.translate(
      offset: Offset(0, 24 * (1 - t)),
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: palette.edge.withValues(alpha: .13), width: 1),
        boxShadow: [
          BoxShadow(color: palette.edge.withValues(alpha: .10),
            offset: const Offset(0, 6), blurRadius: 18),
        ],
      ),
      child: child,
    ),
  );
}

class _PopIn extends StatelessWidget {
  const _PopIn({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final total = delay + const Duration(milliseconds: 260);
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero : total,
      builder: (context, t, child) {
        final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
        return Transform.scale(
          scale: Curves.easeOutBack.transform(local),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Horizontal shake for wrong answers. Change [trigger] to replay it.
class Shake extends StatelessWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(trigger),
    tween: Tween(begin: trigger == 0 ? 1 : 0, end: 1),
    duration: MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero : const Duration(milliseconds: 360),
    builder: (context, t, child) => Transform.translate(
      offset: Offset(math.sin(t * math.pi * 6) * 7 * (1 - t), 0),
      child: child,
    ),
    child: child,
  );
}

/// Common level flow for modules. A map node can contain several levels of its
/// game before the completed node sends the player back to the map.
mixin LevelFlow<T extends StatefulWidget> on State<T> {
  GameLaunch get launch;

  late int level = launch.level;
  bool _reported = false;

  bool get reported => _reported;

  /// Builds a fresh puzzle for [level]. Called on start, replay and advance.
  void resetLevel();

  void reportWin({required int score, required Map<String, num> metrics}) {
    if (_reported) return;
    _reported = true;
    launch.onComplete(GameResult(
      level: level,
      score: score,
      metrics: metrics,
      completesNeuron: launch.mode == GamePlayMode.neuron &&
          level >= launch.maxLevel,
    ));
  }

  void replayLevel() {
    setState(() {
      _reported = false;
      resetLevel();
    });
  }

  void nextLevel() {
    if (level >= launch.maxLevel) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      level++;
      _reported = false;
      resetLevel();
    });
  }
}
