import 'package:flutter/material.dart';
import '../models/scan_point.dart';
import '../models/wall_opening.dart';
import '../utils/measurements.dart';

class FloorPlanCanvasPainter extends CustomPainter {
  final List<ScanPoint> points;
  final Map<int, List<WallOpening>> wallOpenings;
  final bool isClosed;

  FloorPlanCanvasPainter({
    required this.points,
    required this.wallOpenings,
    required this.isClosed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final projection = Measurements.projectToCanvas2D(
      points,
      canvasWidth: size.width,
      canvasHeight: size.height,
      padding: 40.0,
    );

    final projected = projection.projected;
    if (projected.isEmpty) return;

    final offsets = projected.map((p) => p.offset).toList();

    final wallPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < offsets.length - 1; i++) {
      canvas.drawLine(offsets[i], offsets[i + 1], wallPaint);
    }
    if (isClosed && offsets.length > 2) {
      canvas.drawLine(offsets.last, offsets.first, wallPaint);
    }

    final vertexPaint = Paint()..color = Colors.red;
    for (final pt in offsets) {
      canvas.drawCircle(pt, 3, vertexPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
