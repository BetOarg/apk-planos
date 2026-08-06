import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ← Necesario para listEquals
import '../models/scan_point.dart';

class ARLineOverlay extends StatelessWidget {
  final List<ScanPoint> points;
  final bool isClosed;

  const ARLineOverlay({
    super.key,
    required this.points,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ARLinePainter(
          points: points,
          isClosed: isClosed,
        ),
      ),
    );
  }
}

class _ARLinePainter extends CustomPainter {
  final List<ScanPoint> points;
  final bool isClosed;

  _ARLinePainter({required this.points, required this.isClosed});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minX = points[0].x, maxX = points[0].x;
    double minZ = points[0].z, maxZ = points[0].z;

    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.z < minZ) minZ = p.z;
      if (p.z > maxZ) maxZ = p.z;
    }

    final double rangeX = (maxX - minX) == 0 ? 1.0 : (maxX - minX);
    final double rangeZ = (maxZ - minZ) == 0 ? 1.0 : (maxZ - minZ);

    const double margin = 80.0;
    final double drawWidth = size.width - (margin * 2);
    final double drawHeight = size.height - (margin * 2);

    final offsets = List<Offset>.generate(points.length, (i) {
      final p = points[i];
      final dx = margin + ((p.x - minX) / rangeX) * drawWidth;
      final dy = margin + ((p.z - minZ) / rangeZ) * drawHeight;
      return Offset(dx, dy);
    });

    final paintLine = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDashed = Paint()
      ..color = Colors.yellowAccent.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(offsets[0].dx, offsets[0].dy);
    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }

    if (isClosed && offsets.length > 2) path.close();
    canvas.drawPath(path, paintLine);

    if (!isClosed && offsets.length >= 3) {
      canvas.drawLine(offsets.last, offsets.first, paintDashed);
    }
  }

  @override
  // CORRECCIÓN PUNTO 8:
  // shouldRepaint ahora compara el CONTENIDO de la lista, no solo su longitud.
  // listEquals de foundation.dart compara elemento por elemento por valor.
  bool shouldRepaint(covariant _ARLinePainter oldDelegate) =>
      !listEquals(oldDelegate.points, points) ||
      oldDelegate.isClosed != isClosed;
}
