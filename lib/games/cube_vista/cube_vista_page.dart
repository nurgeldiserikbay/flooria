import 'package:flutter/material.dart';
import 'cube_vista_engine.dart';

class CubeVistaPage extends StatefulWidget {
  const CubeVistaPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<CubeVistaPage> createState() => _CubeVistaPageState();
}

class _CubeVistaPageState extends State<CubeVistaPage> {
  late CubeVistaSession session;
  int _revision = 0;
  int? _wrongOption;
  bool _reported = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _wrongOption = null;
    _feedback = null;
    session = CubeVistaSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 91337 + _revision++,
    );
  }

  void _choose(int index) {
    final result = session.choose(index);
    if (result == CubePickResult.invalid) return;

    if (result == CubePickResult.incorrect) {
      setState(() {
        _wrongOption = index;
        _feedback = 'That layout misses one of the views. Try another.';
      });
      return;
    }

    setState(() {
      _wrongOption = null;
      _feedback = result == CubePickResult.complete
          ? null
          : 'All three projections match. Nice work!';
    });

    if (result == CubePickResult.complete && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
      if (widget.floor != null) widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final puzzle = session.current;

    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cube Vista', style: TextStyle(
                      color: _ink, fontSize: 22, fontWeight: FontWeight.w900,
                    )),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete
                          ? 'All 6 structures solved'
                          : 'Structure ${session.roundIndex + 1} of ${CubeVistaSession.roundCount}',
                      style: const TextStyle(
                        color: _muted, fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE8E8F1),
                      color: _indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _CubeResults(
                            correct: session.correctAnswers,
                            mistakes: session.mistakes,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: _softBlue,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white, width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      '3D BLUEPRINT',
                                      style: TextStyle(
                                        color: _indigo, letterSpacing: 1,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Choose the block layout that matches every view.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _ink, fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _ClueViews(clues: puzzle.clues),
                                    const SizedBox(height: 3),
                                    Text('${session.mistakes} slips',
                                      style: const TextStyle(
                                        color: _muted, fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    for (var index = 0;
                                        index < puzzle.options.length;
                                        index++)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            bottom: index ==
                                                    puzzle.options.length - 1
                                                ? 0 : 7,
                                          ),
                                          child: _LayoutOption(
                                            key: ValueKey(
                                              'cube-vista-option-$index',
                                            ),
                                            index: index,
                                            layout: puzzle.options[index],
                                            selectedWrong:
                                                index == _wrongOption,
                                            onTap: () => _choose(index),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 22,
                                child: Center(
                                  child: Text(
                                    _feedback ??
                                        'Use the front, side and top clues.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _wrongOption != null
                                          ? _coral : _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClueViews extends StatelessWidget {
  const _ClueViews({required this.clues});
  final CubeClues clues;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _ProfileView(label: 'FRONT', heights: clues.front),
      _FootprintView(cells: clues.footprint),
      _ProfileView(label: 'SIDE', heights: clues.side),
    ],
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.label, required this.heights});
  final String label;
  final List<int> heights;

  @override
  Widget build(BuildContext context) {
    final maxHeight = heights.fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(
          color: _muted, fontSize: 8, fontWeight: FontWeight.w900,
          letterSpacing: .6,
        )),
        const SizedBox(height: 4),
        SizedBox(
          width: 66,
          height: 43,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < heights.length; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 13,
                    height: heights[index] == 0
                        ? 3
                        : 8 + 30 * heights[index] / maxHeight,
                    decoration: BoxDecoration(
                      color: _blockColors[index],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: const Color(0x558188A8), width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FootprintView extends StatelessWidget {
  const _FootprintView({required this.cells});
  final List<bool> cells;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('TOP', style: TextStyle(
        color: _muted, fontSize: 8, fontWeight: FontWeight.w900,
        letterSpacing: .6,
      )),
      const SizedBox(height: 4),
      SizedBox(
        width: 48,
        height: 43,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemBuilder: (context, index) => DecoratedBox(
            decoration: BoxDecoration(
              color: cells[index] ? _mint : const Color(0xFFE7E9EF),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFFE0E2EA)),
            ),
          ),
        ),
      ),
    ],
  );
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    super.key,
    required this.index,
    required this.layout,
    required this.selectedWrong,
    required this.onTap,
  });

  final int index;
  final CubeLayout layout;
  final bool selectedWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Layout ${String.fromCharCode(65 + index)}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selectedWrong ? _wrongFill : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selectedWrong ? _coral : _edge,
              width: selectedWrong ? 2 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142A324B),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _softBlue,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: const TextStyle(
                    color: _indigo, fontSize: 11, fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              _StackMap(layout: layout),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${layout.totalCubes} blocks',
                  style: const TextStyle(
                    color: _ink, fontSize: 12, fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.touch_app_rounded,
                color: _muted, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StackMap extends StatelessWidget {
  const _StackMap({required this.layout});
  final CubeLayout layout;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 61,
    height: 56,
    child: Column(
      children: [
        for (var row = 0; row < 3; row++)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var column = 0; column < 3; column++)
                  _StackCell(
                    height: layout.heightAt(row, column),
                    color: _blockColors[(row + column) % _blockColors.length],
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _StackCell extends StatelessWidget {
  const _StackCell({required this.height, required this.color});
  final int height;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 19,
    height: 18,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: height == 0
          ? Container(
              width: 13,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E9EF),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (var layer = 0; layer < height; layer++)
                  Container(
                    width: 13,
                    height: 3,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(
                        color: const Color(0x55727C99), width: .4,
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}

class _CubeResults extends StatelessWidget {
  const _CubeResults({
    required this.correct,
    required this.mistakes,
    required this.onRetry,
  });
  final int correct;
  final int mistakes;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.view_in_ar_rounded, size: 62, color: _indigo),
        const SizedBox(height: 10),
        const Text('Great spatial thinking!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink, fontSize: 22, fontWeight: FontWeight.w900,
          )),
        const SizedBox(height: 8),
        Text('$correct layouts matched · $mistakes slips',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('PLAY AGAIN'),
          style: FilledButton.styleFrom(
            backgroundColor: _indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    ),
  );
}

const _paper = Color(0xFFFAFAFD);
const _ink = Color(0xFF4A5064);
const _muted = Color(0xFF8A90A2);
const _indigo = Color(0xFF7F89BE);
const _softBlue = Color(0xFFECEFFC);
const _mint = Color(0xFF91C9B0);
const _edge = Color(0xFFE7E8EF);
const _wrongFill = Color(0xFFFFF0EC);
const _coral = Color(0xFFC57C72);
const _blockColors = <Color>[
  Color(0xFF93B9D8),
  Color(0xFFB4A5D5),
  Color(0xFFEBC47A),
];
