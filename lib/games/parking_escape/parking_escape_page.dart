import 'package:flutter/material.dart';

import 'parking_escape_engine.dart';

/// Sliding-vehicle planning challenge, intentionally independent from the app shell.
class ParkingEscapePage extends StatefulWidget {
  const ParkingEscapePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int moves, int shortestMoves) onSessionEnd;

  @override
  State<ParkingEscapePage> createState() => _ParkingEscapePageState();
}

class _ParkingEscapePageState extends State<ParkingEscapePage> {
  late ParkingEscapeSession game;
  int revision = 0;
  int selectedCar = 0;
  bool rewarded = false;
  int shortest = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    game = ParkingEscapeSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 1327 + revision);
    shortest = game.shortestSolution()?.length ?? 0;
    selectedCar = 0;
    rewarded = false;
  }

  void _move(int id, int delta) {
    if (rewarded || !game.slide(id, delta)) return;
    setState(() => selectedCar = id);
    if (!game.complete || rewarded) return;
    rewarded = true;
    widget.onSessionEnd(game.moves, shortest);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF344B7B);
    final selected = game.car(selectedCar);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FE),
      appBar: AppBar(
        toolbarHeight: 48,
        foregroundColor: navy,
        backgroundColor: const Color(0xFFF6FAFF),
        title: const Text('Parking Escape',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900,
                      color: Color(0xFF7385AB))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC5E9F9), Color(0xFFE2E5FC),
              Color(0xFFFFEBD9)],
          )),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.local_parking_rounded,
                  color: Color(0xFF698BC1), size: 23),
              const SizedBox(width: 8),
              const Expanded(child: Text('Free the coral car!',
                style: TextStyle(color: navy,
                    fontSize: 14, fontWeight: FontWeight.w900))),
              Text('${game.moves} moves',
                style: const TextStyle(color: Color(0xFF6E7DA8),
                    fontWeight: FontWeight.w900, fontSize: 12)),
            ]),
            const SizedBox(height: 7),
            const Text('Swipe a vehicle along its lane, or use the arrows.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF687EA2), fontSize: 12)),
            const SizedBox(height: 10),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              final size = constraints.biggest.shortestSide
                  .clamp(0.0, 432.0).toDouble();
              final cell = (size - 16) / ParkingEscapeSession.size;
              return Center(child: SizedBox(
                width: size,
                height: size,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      border: Border.all(
                          color: const Color(0xFFB8CAE8), width: 2),
                      borderRadius: BorderRadius.circular(20)),
                    child: CustomPaint(painter: _ParkingGridPainter()),
                  )),
                  Positioned(
                    left: size - 9,
                    top: 8 + cell * 2 + cell * .25,
                    child: const Icon(Icons.arrow_forward_rounded,
                      size: 26, color: Color(0xFF36A999))),
                  for (final car in game.cars)
                    Positioned(
                      top: 8 + car.row * cell + 3,
                      left: 8 + car.column * cell + 3,
                      width: (car.horizontal ? car.length : 1) * cell - 6,
                      height: (car.horizontal ? 1 : car.length) * cell - 6,
                      child: GestureDetector(
                        key: ValueKey('parking-car-${car.id}'),
                        onTap: () => setState(() => selectedCar = car.id),
                        onHorizontalDragEnd: car.horizontal
                            ? (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity.abs() > 30) {
                                  _move(car.id, velocity > 0 ? 1 : -1);
                                }
                              }
                            : null,
                        onVerticalDragEnd: !car.horizontal
                            ? (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity.abs() > 30) {
                                  _move(car.id, velocity > 0 ? 1 : -1);
                                }
                              }
                            : null,
                        child: Semantics(
                          button: true,
                          label: car.id == 0
                            ? 'Escape car'
                            : 'Vehicle ${car.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              color: car.id == 0
                                  ? const Color(0xFFFF9E8C)
                                  : [
                                      const Color(0xFF94C6F2),
                                      const Color(0xFFC5ACF0),
                                      const Color(0xFF92DCBD),
                                    ][(car.id - 1) % 3],
                              border: Border.all(
                                color: car.id == selectedCar
                                    ? const Color(0xFF405F9D)
                                    : Colors.white,
                                width: car.id == selectedCar ? 3 : 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Icon(
                              car.id == 0
                                  ? Icons.arrow_forward_rounded
                                  : car.horizontal
                                      ? Icons.swap_horiz_rounded
                                      : Icons.swap_vert_rounded,
                              size: 28,
                              color: const Color(0xFF466185))),
                          ),
                        ),
                      ),
                    ),
                ]),
              ));
            })),
            const SizedBox(height: 10),
            if (game.complete)
              const Text('The exit is clear!',
                  style: TextStyle(color: Color(0xFF2D9C88),
                      fontWeight: FontWeight.w900))
            else
              Text('Vehicle ${selected.id == 0 ? 'ESCAPE' : selected.id} selected',
                  style: const TextStyle(color: Color(0xFF5E7095),
                      fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.filledTonal(
                key: const ValueKey('parking-negative'),
                onPressed: rewarded
                    ? null : () => _move(selected.id, -1),
                tooltip: selected.horizontal ? 'Move left' : 'Move up',
                icon: Icon(selected.horizontal
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_upward_rounded),
              ),
              const SizedBox(width: 14),
              IconButton.filledTonal(
                key: const ValueKey('parking-positive'),
                onPressed: rewarded
                    ? null : () => _move(selected.id, 1),
                tooltip: selected.horizontal ? 'Move right' : 'Move down',
                icon: Icon(selected.horizontal
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_downward_rounded),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => setState(() {
                  revision++;
                  _restart();
                }),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD38B),
                    foregroundColor: navy),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'RESTART'),
              ),
            ]),
          ]),
        ),
      ))),
    );
  }
}

class _ParkingGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD9E6F5)
      ..strokeWidth = 1.5;
    for (var i = 1; i < ParkingEscapeSession.size; i++) {
      final coordinate = i * size.width / ParkingEscapeSession.size;
      canvas.drawLine(Offset(coordinate, 0),
          Offset(coordinate, size.height), paint);
      canvas.drawLine(Offset(0, coordinate),
          Offset(size.width, coordinate), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParkingGridPainter oldDelegate) => false;
}
