import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import 'number_hunt_engine.dart';

const _ink = Color(0xFF273D75);
const _muted = Color(0xFF7887A8);
const _accent = Color(0xFF4FAEAD);
const _paper = Color(0xFFF4F6FF);

Widget buildNumberHuntPage(BuildContext context, GameLaunch launch) =>
    NumberHuntPage(launch: launch);

class NumberHuntPage extends StatefulWidget {
  const NumberHuntPage({super.key, required this.launch});

  final GameLaunch launch;

  @override
  State<NumberHuntPage> createState() => _NumberHuntPageState();
}

class _NumberHuntPageState extends State<NumberHuntPage> {
  late NumberHuntEngine _engine;
  late int _currentLevel;
  int? _feedbackIndex;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.launch.level;
    _engine = NumberHuntEngine.forLevel(_currentLevel);
  }

  void _tapCell(int index) {
    if (_complete) return;
    final result = _engine.tap(index);
    if (result == NumberHuntTapResult.ignored) return;

    if (result == NumberHuntTapResult.incorrect) {
      HapticFeedback.selectionClick();
      setState(() => _feedbackIndex = index);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _feedbackIndex = null;
      _complete = result == NumberHuntTapResult.completed;
    });
    if (_complete) {
      widget.launch.onComplete(GameResult(
        level: _currentLevel,
        score: _engine.score,
        metrics: {'focus': max(0, 100 - _engine.mistakes * 8)},
      ));
    }
  }

  void _continueAfterLevel() {
    if (_currentLevel >= widget.launch.maxLevel) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _currentLevel++;
      _engine = NumberHuntEngine.forLevel(_currentLevel);
      _feedbackIndex = null;
      _complete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = _engine.currentRound;
    final roundNumber = _complete ? _engine.rounds.length : _engine.roundIndex + 1;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        titleSpacing: 4,
        title: Text('Find the Number  ·  $_currentLevel',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(child: _LevelPill(level: _currentLevel)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, constraints) {
          const gap = 7.0;
          final boardWidth = (constraints.maxWidth - 44)
              .clamp(260.0, 420.0).toDouble();
          final naturalCellWidth =
              (boardWidth - gap * (_engine.columns - 1)) / _engine.columns;
          final gridRoom = (constraints.maxHeight - 245)
              .clamp(180.0, 420.0).toDouble();
          final heightPerCell =
              (gridRoom - gap * (_engine.rows - 1)) / _engine.rows;
          final cellHeight = min(naturalCellWidth, heightPerCell)
              .clamp(38.0, 76.0).toDouble();
          final gridHeight = cellHeight * _engine.rows + gap * (_engine.rows - 1);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: Column(
                  children: [
                    Text(
                      _complete ? 'LEVEL COMPLETE' : 'ROUND $roundNumber / ${_engine.rounds.length}',
                      key: const ValueKey('number-hunt-status'),
                      style: TextStyle(
                        color: _complete ? const Color(0xFF43A987) : _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 76,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _accent.withValues(alpha: .3)),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: .12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${round.target}',
                        key: const ValueKey('number-hunt-target'),
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _complete
                          ? 'You found every number.'
                          : _feedbackIndex == null
                              ? 'Find and tap this number.'
                              : 'Not this one — try again.',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _complete
                                ? 1
                                : _engine.roundIndex / _engine.rounds.length,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E7F5),
                            color: _complete ? const Color(0xFF43A987) : _accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${_engine.mistakes} missed',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        )),
                    ]),
                    const Spacer(),
                    SizedBox(
                      width: naturalCellWidth * _engine.columns +
                          gap * (_engine.columns - 1),
                      height: gridHeight,
                      child: GridView.builder(
                        key: ValueKey('number-hunt-board-${_currentLevel}-${_engine.roundIndex}'),
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _engine.columns,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          mainAxisExtent: cellHeight,
                        ),
                        itemCount: _engine.cellCount,
                        itemBuilder: (context, index) => _NumberCell(
                          key: ValueKey('number-cell-$index'),
                          value: round.numbers[index],
                          wrong: _feedbackIndex == index,
                          enabled: !_complete,
                          onTap: () => _tapCell(index),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_complete)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _continueAfterLevel,
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _currentLevel >= widget.launch.maxLevel
                                ? 'FINISH'
                                : 'NEXT LEVEL',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      )
                    else
                      Text('TARGET ${roundNumber.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text('LV $level', style: const TextStyle(
      color: _accent, fontSize: 11, fontWeight: FontWeight.w900)),
  );
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({
    super.key,
    required this.value,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 120),
    decoration: BoxDecoration(
      color: wrong ? const Color(0xFFFFE2E3) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: wrong ? const Color(0xFFE35C66) : const Color(0xFFE5EAF4),
        width: wrong ? 2 : 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C273D75),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('number-hunt-cell-button'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Center(
          child: Text('$value', style: TextStyle(
            color: wrong ? const Color(0xFFE35C66) : _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          )),
        ),
      ),
    ),
  );
}
