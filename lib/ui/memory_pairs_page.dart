import 'package:flutter/material.dart';
import '../game/memory_pairs.dart';
import 'floor_victory.dart' show VictoryAction, showFloorVictory;

/// Standalone memory puzzle. It owns visuals and game state only.
class MemoryPairsPage extends StatefulWidget {
  const MemoryPairsPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int pairs, int moves) onSessionEnd;

  @override
  State<MemoryPairsPage> createState() => _MemoryPairsPageState();
}

class _MemoryPairsPageState extends State<MemoryPairsPage> {
  static const colors = [
    Color(0xFF72C8F0), Color(0xFFFCB879),
    Color(0xFFB5A0F9), Color(0xFF84DABB),
    Color(0xFFFF9FBF), Color(0xFFFFD571),
    Color(0xFF82C0FA), Color(0xFFC7CE83),
  ];
  static const symbols = [
    Icons.stars_rounded, Icons.favorite_rounded, Icons.bolt_rounded,
    Icons.spa_rounded, Icons.pets_rounded, Icons.music_note_rounded,
    Icons.wb_sunny_rounded, Icons.diamond_rounded,
  ];

  late MemoryPairs session;
  int revision = 0;
  bool rewarded = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = MemoryPairs(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 631 + revision,
      pairCount: 6,
    );
    rewarded = false;
  }

  Future<void> _tap(int index) async {
    if (rewarded || !session.reveal(index)) return;
    setState(() {});
    if (session.isResolving) {
      await Future<void>.delayed(const Duration(milliseconds: 720));
      if (!mounted) return;
      session.hideMismatch();
      setState(() {});
    }
    if (!session.isComplete || rewarded) return;
    rewarded = true;
    widget.onSessionEnd(session.pairsFound, session.moves);
    if (widget.floor == null) {
      setState(() {});
      return;
    }
    widget.onComplete();
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'All ${session.pairCount} pairs discovered!',
      detail: 'Your next neuron is ready.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE3EAFE),
    appBar: AppBar(
      toolbarHeight: 48,
      title: const Text('Memory Pairs',
        style: TextStyle(fontWeight: FontWeight.w900)),
      backgroundColor: const Color(0xFFEBF3FF),
      foregroundColor: const Color(0xFF2F447D),
      actions: [
        if (widget.floor != null) Center(child: Padding(
          padding: const EdgeInsets.only(right: 17),
          child: Text('LEVEL ${widget.floor}', style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w900,
            color: Color(0xFF6F7EAC))))),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFB6E5F7), Color(0xFFE8DCFA), Color(0xFFFFE7D3)])),
        padding: const EdgeInsets.fromLTRB(15, 11, 15, 15),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFF6D60C8), size: 22),
            const SizedBox(width: 7),
            const Expanded(child: Text('Find the matching pairs',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: Color(0xFF374C86)))),
            Text('${session.pairsFound} / ${session.pairCount}',
              style: const TextStyle(color: Color(0xFF6753B6),
                fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          Expanded(child: LayoutBuilder(builder: (context, bounds) {
            final width = bounds.maxWidth;
            final cardWidth = (width - 24) / 3;
            final cardHeight = (bounds.maxHeight - 36) / 4;
            final cardSize = cardWidth < cardHeight ? cardWidth : cardHeight;
            return Center(child: SizedBox(
              width: cardSize * 3 + 24,
              height: cardSize * 4 + 36,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12, crossAxisSpacing: 12),
                itemCount: session.values.length,
                itemBuilder: (context, index) {
                  final visible = session.isFaceUp(index);
                  final symbol = session.values[index];
                  final paired = session.matched.contains(index);
                  return Semantics(
                    button: true,
                    label: visible ? 'Symbol ${symbol + 1}' : 'Hidden card ${index + 1}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _tap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 190),
                        decoration: BoxDecoration(
                          color: paired
                            ? const Color(0xFFCFF7DF)
                            : visible ? Colors.white
                              : const Color(0xFF7774D4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(
                            color: Color(0x225364A2), blurRadius: 7,
                            offset: Offset(0, 4))]),
                        child: Center(child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 130),
                          child: visible
                            ? Icon(symbols[symbol],
                                key: ValueKey('symbol-$index'),
                                size: cardSize * .50,
                                color: colors[symbol])
                            : Icon(Icons.bubble_chart_rounded,
                                key: ValueKey('back-$index'),
                                color: const Color(0xFFDCE7FF),
                                size: cardSize * .43))),
                      ),
                    ),
                  );
                },
              ),
            ));
          })),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(
              session.isComplete
                ? 'Perfect! All pairs matched.'
                : '${session.moves} turns',
              style: const TextStyle(color: Color(0xFF536D9B),
                fontSize: 13, fontWeight: FontWeight.w800))),
            FilledButton.icon(
              onPressed: () => setState(() { revision++; _restart(); }),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD17C),
                foregroundColor: const Color(0xFF334376)),
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text('RESTART')),
          ]),
        ]),
      ),
    ))),
  );
}
