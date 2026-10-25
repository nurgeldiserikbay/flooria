import 'package:flutter/material.dart';
import '../game/pattern_echo.dart';
import 'floor_victory.dart';

/// Watch glowing pads, then repeat the pattern. Independent game screen.
class PatternEchoPage extends StatefulWidget {
  const PatternEchoPage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int stages, int mistakes) onSessionEnd;

  @override
  State<PatternEchoPage> createState() => _PatternEchoPageState();
}

class _PatternEchoPageState extends State<PatternEchoPage> {
  static const colors = [
    Color(0xFF67C5F5), Color(0xFFFFAF8F),
    Color(0xFF9F9AF4), Color(0xFF79D6AC),
  ];
  late PatternEchoSession game;
  int revision = 0;
  int playbackToken = 0;
  int? glowing;
  bool watching = true;
  bool awarded = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    playbackToken++;
    game = PatternEchoSession(seed: widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 631 + revision);
    watching = true;
    glowing = null;
    awarded = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _preview());
  }

  Future<void> _preview() async {
    if (!mounted || awarded) return;
    final token = ++playbackToken;
    setState(() { watching = true; glowing = null; });
    await Future<void>.delayed(const Duration(milliseconds: 440));
    if (!mounted || token != playbackToken) return;
    for (final pad in game.pattern) {
      setState(() => glowing = pad);
      await Future<void>.delayed(const Duration(milliseconds: 510));
      if (!mounted || token != playbackToken) return;
      setState(() => glowing = null);
      await Future<void>.delayed(const Duration(milliseconds: 190));
      if (!mounted || token != playbackToken) return;
    }
    setState(() => watching = false);
  }

  Future<void> _tap(int index) async {
    if (watching || awarded || game.complete) return;
    final result = game.input(index);
    if (result == -1) {
      _preview(); // retry the same stage after a mistake
      return;
    }
    setState(() {});
    if (result == 1) {
      _preview();
      return;
    }
    if (result != 2) return;
    awarded = true;
    widget.onSessionEnd(game.stage, game.mistakes);
    if (widget.floor == null) return;
    widget.onComplete();
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'All three patterns remembered!',
      detail: 'Your next neuron is waiting.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  void dispose() {
    playbackToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE7E1FC),
    appBar: AppBar(
      toolbarHeight: 48,
      title: const Text('Pattern Echo', style: TextStyle(
        fontWeight: FontWeight.w900)),
      backgroundColor: const Color(0xFFF0ECFF),
      foregroundColor: const Color(0xFF514A87),
      actions: [
        if (widget.floor != null)
          Center(child: Padding(padding: const EdgeInsets.only(right: 18),
            child: Text('LEVEL ${widget.floor}', style: const TextStyle(
              color: Color(0xFF8577AF), fontSize: 12,
              fontWeight: FontWeight.w900)))),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFD9CFFF), Color(0xFFEDEAFF), Color(0xFFD6F3F6)])),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 15),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFF7363C8)),
            const SizedBox(width: 8),
            Expanded(child: Text(game.complete ? 'All patterns complete'
              : watching ? 'Watch the lights' : 'Repeat the pattern',
              style: const TextStyle(color: Color(0xFF514984),
                fontWeight: FontWeight.w900, fontSize: 15))),
            Text('${game.stage.clamp(0, 3)} / 3',
              style: const TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF6B59B9))),
          ]),
          const SizedBox(height: 10),
          Expanded(child: LayoutBuilder(builder: (context, bounds) {
            final size = bounds.biggest.shortestSide.clamp(0.0, 390.0).toDouble();
            return Center(child: SizedBox.square(dimension: size,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 14,
                  mainAxisSpacing: 14),
                itemCount: 4,
                itemBuilder: (context, i) => Semantics(
                  button: true, label: 'Pattern pad ${i + 1}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(27),
                    onTap: watching || game.complete ? null : () => _tap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: glowing == i
                          ? [Color.lerp(colors[i], Colors.white, .6)!, colors[i]]
                          : [Color.lerp(colors[i], Colors.white, .34)!, colors[i]]),
                        borderRadius: BorderRadius.circular(27),
                        border: Border.all(color: const Color(0xF5FFFFFF),
                          width: glowing == i ? 4 : 2),
                        boxShadow: [BoxShadow(
                          color: colors[i].withValues(
                            alpha: glowing == i ? .65 : .17),
                          blurRadius: glowing == i ? 27 : 8,
                          spreadRadius: glowing == i ? 4 : 0)]),
                      child: Center(child: Icon(
                        const [Icons.circle_rounded, Icons.square_rounded,
                          Icons.change_history_rounded, Icons.star_rounded][i],
                        size: size * .12, color: const Color(0xDDFFFFFF))),
                    ),
                  ),
                ),
              ),
            ));
          })),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('${game.mistakes} mistakes',
              style: const TextStyle(color: Color(0xFF776D9F),
                fontWeight: FontWeight.w800))),
            FilledButton.icon(
              onPressed: () => setState(() { revision++; _restart(); }),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFDF9B),
                foregroundColor: const Color(0xFF61517C)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RESTART')),
          ]),
        ]),
      ),
    ))),
  );
}
