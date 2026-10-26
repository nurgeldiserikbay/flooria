import 'package:flutter/material.dart';

import 'hue_mixer_engine.dart';

class HueMixerPage extends StatefulWidget {
  const HueMixerPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<HueMixerPage> createState() => _HueMixerPageState();
}

class _HueMixerPageState extends State<HueMixerPage> {
  late HueMixerSession session;
  int _revision = 0;
  int? _selectedRatio;
  bool _reported = false;
  String? _feedback;
  bool? _lastWasCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    final level = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 49979687 + _revision;
    _revision++;
    session = HueMixerSession(seed: seed, level: level);
    _selectedRatio = null;
    _reported = false;
    _feedback = null;
    _lastWasCorrect = null;
  }

  void _selectRatio(int ratio) {
    if (session.answered) return;
    setState(() => _selectedRatio = ratio);
  }

  void _submit() {
    final ratio = _selectedRatio;
    if (ratio == null) return;
    final result = session.submit(ratio);
    if (result == HueAnswerResult.invalid) return;
    setState(() {
      _lastWasCorrect = result == HueAnswerResult.correct;
      _feedback = _lastWasCorrect!
          ? 'Beautiful blend — that is the target mix.'
          : 'Close the color gap. Compare the target and preview.';
    });
  }

  void _continue() {
    if (!session.advance()) return;
    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
      if (widget.floor != null && session.passed) widget.onComplete();
    }
    setState(() {
      _selectedRatio = null;
      _feedback = null;
      _lastWasCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = session.finished;
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Hue Mixer',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${session.mistakes} misses',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      finished
                          ? 'Mixing session complete'
                          : 'Blend ${session.roundIndex + 1} of ${HueMixerSession.roundCount}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE7ECE8),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: finished
                        ? _MixerResults(
                            correct: session.correctAnswers,
                            mistakes: session.mistakes,
                            passed: session.passed,
                            onRetry: () => setState(_startSession),
                          )
                        : _mixingArea(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mixingArea() {
    final round = session.current;
    final previewRatio = _selectedRatio ?? 50;
    final preview = HueColor.blend(
      round.firstColor,
      round.secondColor,
      previewRatio,
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _softLilac,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'MATCH THE TARGET',
                      style: TextStyle(
                        color: _purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose the blend ratio that makes this color.',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ColorSwatch(
                color: round.targetColor,
                size: 52,
                key: const ValueKey('hue-target'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(child: _SourceCard(color: round.firstColor, label: 'A')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.add_rounded, color: _muted, size: 22),
            ),
            Expanded(child: _SourceCard(color: round.secondColor, label: 'B')),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _edge),
          ),
          child: Row(
            children: [
              _ColorSwatch(
                color: preview,
                size: 42,
                key: const ValueKey('hue-preview'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR PREVIEW',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$previewRatio% A  ·  ${100 - previewRatio}% B',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _selectedRatio == null ? 'Pick a ratio' : 'Preview updated',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            session.answered ? 'Your mix' : 'How much of color A?',
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        _RatioChoices(
          choices: round.ratioChoices,
          selected: _selectedRatio,
          enabled: !session.answered,
          onSelect: _selectRatio,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: Center(
            child: Text(
              _feedback ?? 'Compare both swatches, then choose a ratio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _lastWasCorrect == false ? _coral : _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: FilledButton.icon(
            key: const ValueKey('hue-mixer-action'),
            onPressed: session.answered
                ? _continue
                : _selectedRatio == null
                    ? null
                    : _submit,
            icon: Icon(
              session.answered
                  ? Icons.arrow_forward_rounded
                  : Icons.palette_rounded,
            ),
            label: Text(
              session.answered
                  ? session.roundIndex == HueMixerSession.roundCount - 1
                      ? 'SEE RESULTS'
                      : 'NEXT BLEND'
                  : 'MIX COLORS',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              disabledBackgroundColor: const Color(0xFFDDE7E0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatioChoices extends StatelessWidget {
  const _RatioChoices({
    required this.choices,
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  final List<int> choices;
  final int? selected;
  final bool enabled;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = choices.length <= 3 ? 3 : choices.length <= 5 ? 5 : 4;
          final rows = (choices.length / columns).ceil();
          final tileWidth =
              (constraints.maxWidth - (columns - 1) * 6) / columns;
          final tileHeight = tileWidth / 1.65;
          return SizedBox(
            height: rows * tileHeight + (rows - 1) * 6,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: choices.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.65,
              ),
              itemBuilder: (context, index) {
                final ratio = choices[index];
                final isSelected = selected == ratio;
                return Material(
                  color: isSelected ? _softMint : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: ValueKey('hue-ratio-$ratio'),
                    onTap: enabled ? () => onSelect(ratio) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _teal : _edge,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$ratio / ${100 - ratio}',
                          style: TextStyle(
                            color: isSelected ? _deepTeal : _ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.color, required this.label});

  final HueColor color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _edge),
        ),
        child: Row(
          children: [
            _ColorSwatch(color: color, size: 38),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'COLOR $label',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    color.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    super.key,
    required this.color,
    required this.size,
  });

  final HueColor color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, color.red, color.green, color.blue),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0x1F405149), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1453655B),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      );
}

class _MixerResults extends StatelessWidget {
  const _MixerResults({
    required this.correct,
    required this.mistakes,
    required this.passed,
    required this.onRetry,
  });

  final int correct;
  final int mistakes;
  final bool passed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.palette_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _teal : _coral,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Color artist!' : 'Mix another round',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct blends matched · $mistakes misses',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('PLAY AGAIN'),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
}

const _paper = Color(0xFFFAFBF8);
const _ink = Color(0xFF46504B);
const _muted = Color(0xFF8B9690);
const _teal = Color(0xFF5D9E88);
const _deepTeal = Color(0xFF4C8272);
const _coral = Color(0xFFC97D72);
const _purple = Color(0xFF8274AE);
const _softLilac = Color(0xFFF0ECF8);
const _softMint = Color(0xFFE5F2EA);
const _edge = Color(0xFFE6ECE7);
