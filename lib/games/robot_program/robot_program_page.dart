import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'robot_program_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEEF3FF), surface: Colors.white, ink: Color(0xFF465478),
  muted: Color(0xFF8290B0), accent: Color(0xFF6885D0), edge: Color(0xFF465478),
);

Widget buildRobotProgramPage(BuildContext context, GameLaunch launch) =>
    RobotProgramPage(launch: launch);

class RobotProgramPage extends StatefulWidget {
  const RobotProgramPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<RobotProgramPage> createState() => _RobotProgramPageState();
}

class _RobotProgramPageState extends State<RobotProgramPage> with LevelFlow<RobotProgramPage> {
  late RobotProgramEngine _engine;
  String _message = 'BUILD A PROGRAM TO REACH THE EXIT';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = RobotProgramEngine.forLevel(level);
    _message = 'BUILD A PROGRAM TO REACH THE EXIT';
  }

  void _add(RobotCommand command) {
    if (!_engine.add(command)) {
      setState(() => _message = 'PROGRAM FULL · UNDO A COMMAND');
      return;
    }
    setState(() => _message = 'COMMAND ADDED');
    HapticFeedback.selectionClick();
  }

  void _run() {
    final result = _engine.run();
    setState(() => _message = switch (result) {
      ProgramRun.completed => 'EXIT REACHED',
      ProgramRun.crashed => 'BLOCKED · EDIT THE PROGRAM',
      ProgramRun.incomplete => 'NOT THERE YET · ADD COMMANDS',
      ProgramRun.ran => 'PROGRAM RAN',
      ProgramRun.ignored => 'ADD A COMMAND FIRST',
    });
    if (result == ProgramRun.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == ProgramRun.crashed) {
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GameScaffold(
    palette: _palette, title: 'Robot Program', level: level,
    actions: [
      ChunkyIconButton(icon: Icons.backspace_outlined, tooltip: 'Undo command',
        palette: _palette, onPressed: reported ? null : () => setState(() { _engine.removeLast(); })),
      const SizedBox(width: 8),
      ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
        palette: _palette, onPressed: reported ? null : replayLevel),
    ],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 32,
        constraints.maxHeight - (reported ? 360 : 310)).clamp(225.0, 360.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'COMMANDS', value: '${_engine.program.length}/${_engine.commandLimit}', palette: _palette),
              StatChip(label: 'RUNS', value: '${_engine.runs}', palette: _palette),
            ])),
          const SizedBox(height: 10),
          Container(width: side, height: side, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFD3DCF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
              itemCount: RobotProgramEngine.side * RobotProgramEngine.side,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: RobotProgramEngine.side, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final wall = _engine.walls.contains(cell);
                final isRobot = cell == _engine.robot;
                final isGoal = cell == _engine.goal;
                final row = cell ~/ RobotProgramEngine.side + 1;
                final column = cell % RobotProgramEngine.side + 1;
                final description = [
                  'Row $row, column $column',
                  if (wall) 'wall' else 'open path',
                  if (cell == _engine.start) 'start',
                  if (isGoal) 'exit',
                  if (isRobot) 'robot facing ${const ['north', 'east', 'south', 'west'][_engine.heading]}',
                ].join(', ');
                return Semantics(
                  key: ValueKey('robot-cell-$cell'),
                  label: description,
                  child: AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 170),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: wall ? null : LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: isGoal
                        ? const [Color(0xFFDBF8E3), Color(0xFFBAEACB)]
                        : isRobot
                        ? const [Color(0xFFEBEFFF), Color(0xFFD4E2FF)]
                        : const [Color(0xFFFFFFFF), Color(0xFFF3F6FF)],
                    ),
                    color: wall ? const Color(0xFF666F91) : null,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isGoal ? const Color(0xFF53A875)
                        : isRobot ? _palette.accent
                        : wall ? _palette.edge : const Color(0xFFDCE2F2),
                      width: isRobot || isGoal ? 1.7 : 1,
                    )),
                  child: Center(child: isRobot
                    ? Transform.rotate(angle: _engine.heading * pi / 2,
                        child: Icon(Icons.smart_toy_rounded, size: side / 12,
                          color: const Color(0xFF5C80CC)))
                    : cell == _engine.goal ? const Icon(Icons.flag_rounded, color: Color(0xFF65AC83))
                    : cell == _engine.start ? const Icon(Icons.play_arrow_rounded,
                        size: 18, color: Color(0xFF69A88B))
                    : wall ? const Icon(Icons.square_rounded, size: 10, color: Color(0xFF8C94AE)) : null),
                ));
              },
            )),
          const SizedBox(height: 8),
          SizedBox(width: min(constraints.maxWidth - 30, 370).toDouble(),
            child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4,
              children: [
                for (var i = 0; i < _engine.commandLimit; i++)
                  Semantics(
                    key: ValueKey('robot-program-slot-$i'),
                    label: 'Command ${i + 1}: ${i < _engine.program.length ? _commandName(_engine.program[i]) : 'empty'}',
                    child: AnimatedContainer(
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
                    width: 27, height: 29,
                    decoration: BoxDecoration(color: i < _engine.program.length
                      ? const Color(0xFFE5EBFC) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _palette.edge.withValues(alpha: .45))),
                    child: Center(child: i < _engine.program.length
                      ? Icon(_commandIcon(_engine.program[i]), size: 16, color: _palette.ink)
                      : Text('${i + 1}', style: TextStyle(color: _palette.muted, fontSize: 9,
                          fontWeight: FontWeight.w800))))),
              ],
            )),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _CommandButton(icon: Icons.arrow_upward_rounded, label: 'MOVE',
              onTap: reported ? null : () => _add(RobotCommand.forward)),
            const SizedBox(width: 8),
            _CommandButton(icon: Icons.rotate_left_rounded, label: 'LEFT',
              onTap: reported ? null : () => _add(RobotCommand.turnLeft)),
            const SizedBox(width: 8),
            _CommandButton(icon: Icons.rotate_right_rounded, label: 'RIGHT',
              onTap: reported ? null : () => _add(RobotCommand.turnRight)),
          ]),
          const SizedBox(height: 6),
          if (!reported)
            SizedBox(width: 200, height: 44,
              child: ChunkyButton(onPressed: _engine.program.isEmpty ? null : _run,
                color: _palette.accent, edgeColor: _palette.edge, depth: 3, radius: 12,
                child: const Text('RUN PROGRAM', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, letterSpacing: 1)))),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.runs <= 2 ? 3 : _engine.runs <= 4 ? 2 : 1,
                detail: 'Programmed the robot to the exit.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            HintLine(_message, palette: _palette),
        ]));
    }),
  );
  }
}

String _commandName(RobotCommand command) => switch (command) {
  RobotCommand.forward => 'move forward',
  RobotCommand.turnLeft => 'turn left',
  RobotCommand.turnRight => 'turn right',
};

IconData _commandIcon(RobotCommand command) => switch (command) {
  RobotCommand.forward => Icons.arrow_upward_rounded,
  RobotCommand.turnLeft => Icons.rotate_left_rounded,
  RobotCommand.turnRight => Icons.rotate_right_rounded,
};

class _CommandButton extends StatelessWidget {
  const _CommandButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: 82, height: 48,
    child: ChunkyButton(onPressed: onTap, color: Colors.white, edgeColor: _palette.edge,
      depth: 3, radius: 11, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: _palette.accent),
        Text(label, style: TextStyle(color: _palette.ink, fontSize: 8,
          fontWeight: FontWeight.w900, letterSpacing: .5)),
      ])));
}
