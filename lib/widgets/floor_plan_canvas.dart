import 'dart:math';
import 'package:flutter/material.dart';
import '../models/scan_point.dart';
import '../models/wall_opening.dart';
import '../models/projected_point.dart';
import '../utils/measurements.dart';

/// Modo de edicion de vertices en el plano 2D.
enum EditMode {
  /// Movimiento restringido al eje vectorial de la pared previa (default).
  /// Preserva angulos y solo modifica la longitud del tramo.
  restricted,

  /// Movimiento libre en el plano XZ.
  /// Permite reposicionar cualquier vertice sin restriccion angular.
  free,
}

class InteractiveFloorPlan extends StatefulWidget {
  final List<ScanPoint> points;
  final Map<int, List<WallOpening>> wallOpenings;
  final bool isClosed;
  final double northHeading;
  final EditMode editMode;
  final Function(int index, ScanPoint updatedPoint)? onPointUpdated;
  final Function(int segmentIndex)? onSegmentTap;

  const InteractiveFloorPlan({
    super.key,
    required this.points,
    required this.wallOpenings,
    required this.isClosed,
    this.northHeading = 0.0,
    this.editMode = EditMode.restricted,
    this.onPointUpdated,
    this.onSegmentTap,
  });

  @override
  State<InteractiveFloorPlan> createState() => _InteractiveFloorPlanState();
}

class _InteractiveFloorPlanState extends State<InteractiveFloorPlan> {
  int? _activeDragIndex;
  ProjectionResult? _lastProjection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // CORRECCIÓN PUNTO 5: projectToCanvas2D ahora existe en Measurements
        _lastProjection = Measurements.projectToCanvas2D(
          widget.points,
          canvasWidth: constraints.maxWidth,
          canvasHeight: constraints.maxHeight,
          padding: 50.0,
        );

        final projected = _lastProjection!.projected;

        return GestureDetector(
          onTapDown: (details) => _handleTapDown(details.localPosition, projected),
          onPanStart: (details) => _handlePanStart(details.localPosition, projected),
          onPanUpdate: (details) => _handlePanUpdate(details.delta, projected),
          onPanEnd: (_) => setState(() => _activeDragIndex = null),
          child: Container(
            color: Colors.white,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _FloorPlanPainter(
                points: widget.points,
                wallOpenings: widget.wallOpenings,
                isClosed: widget.isClosed,
                showMeasurements: true,
                selectedIndex: _activeDragIndex,
                northHeading: widget.northHeading,
                projection: _lastProjection!,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTapDown(Offset touchPos, List<ProjectedPoint> projected) {
    if (widget.onSegmentTap == null || projected.length < 2) return;

    const double tapThreshold = 20.0;
    for (int i = 0; i < projected.length; i++) {
      final nextIdx = (i + 1) % projected.length;
      if (!widget.isClosed && nextIdx == 0) break;

      final p1 = projected[i].offset;
      final p2 = projected[nextIdx].offset;

      final dist = _distanceToSegment(touchPos, p1, p2);
      if (dist <= tapThreshold) {
        widget.onSegmentTap!(i);
        break;
      }
    }
  }

  double _distanceToSegment(Offset p, Offset v, Offset w) {
    final l2 = (w - v).distanceSquared;
    if (l2 == 0) return (p - v).distance;
    final t = (((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2).clamp(0.0, 1.0);
    final projection = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
    return (p - projection).distance;
  }

  void _handlePanStart(Offset touchPos, List<ProjectedPoint> projected) {
    const double touchRadius = 32.0;
    for (int i = 0; i < projected.length; i++) {
      final ptOffset = projected[i].offset;
      if ((touchPos - ptOffset).distance <= touchRadius) {
        setState(() => _activeDragIndex = i);
        break;
      }
    }
  }

  void _handlePanUpdate(Offset delta, List<ProjectedPoint> projected) {
    if (_activeDragIndex == null || widget.onPointUpdated == null) return;

    final int targetIdx = _activeDragIndex!;
    final double scale = _lastProjection?.scale ?? 1.0;
    if (scale <= 0) return;

    final ScanPoint pTarget = widget.points[targetIdx];

    if (widget.editMode == EditMode.free) {
      // Modo libre: aplicar delta directamente en el plano XZ
      final double newX = pTarget.x + (delta.dx / scale);
      final double newZ = pTarget.z + (delta.dy / scale);
      widget.onPointUpdated!(targetIdx, ScanPoint.fromCoordinates(newX, pTarget.y, newZ));
    } else {
      // Modo restringido: proyectar delta sobre el vector unitario de la pared previa
      final int prevIdx = (targetIdx - 1 + widget.points.length) % widget.points.length;
      final ScanPoint pPrev = widget.points[prevIdx];

      final double dirX = pTarget.x - pPrev.x;
      final double dirZ = pTarget.z - pPrev.z;
      final double currentLen = sqrt(dirX * dirX + dirZ * dirZ);
      if (currentLen < 0.001) return;

      final double uX = dirX / currentLen;
      final double uZ = dirZ / currentLen;

      final double deltaMetersX = delta.dx / scale;
      final double deltaMetersZ = delta.dy / scale;

      final double projectedDelta = (deltaMetersX * uX) + (deltaMetersZ * uZ);
      final double newLen = (currentLen + projectedDelta).clamp(0.35, 100.0);

      final double newX = pPrev.x + (uX * newLen);
      final double newZ = pPrev.z + (uZ * newLen);

      widget.onPointUpdated!(targetIdx, ScanPoint.fromCoordinates(newX, pTarget.y, newZ));
    }
  }
}

class _FloorPlanPainter extends CustomPainter {
  final List<ScanPoint> points;
  final Map<int, List<WallOpening>> wallOpenings;
  final bool isClosed;
  final bool showMeasurements;
  final int? selectedIndex;
  final double northHeading;
  final ProjectionResult projection;

  static final _linePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final _doorPaint = Paint()
    ..color = const Color(0xFF1565C0)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  static final _windowPaint = Paint()
    ..color = const Color(0xFF00838F)
    ..strokeWidth = 4.0
    ..style = PaintingStyle.stroke;

  static final _clearPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 4.0;

  _FloorPlanPainter({
    required this.points,
    required this.wallOpenings,
    required this.isClosed,
    required this.showMeasurements,
    this.selectedIndex,
    this.northHeading = 0.0,
    required this.projection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || projection.projected.isEmpty) return;

    final offsets = projection.projected.map((p) => p.offset).toList();

    for (int i = 0; i < offsets.length - 1; i++) {
      canvas.drawLine(offsets[i], offsets[i + 1], _linePaint);
    }
    if (isClosed && offsets.length > 2) {
      canvas.drawLine(offsets.last, offsets.first, _linePaint);
    }

    _drawOpenings(canvas, offsets);

    for (int i = 0; i < offsets.length; i++) {
      final isSelected = (i == selectedIndex);
      final pinPaint = Paint()..color = isSelected ? Colors.orangeAccent : Colors.redAccent;
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final radius = isSelected ? 10.0 : 7.0;
      canvas.drawCircle(offsets[i], radius, pinPaint);
      canvas.drawCircle(offsets[i], radius, strokePaint);
    }

    if (showMeasurements && points.length > 1) {
      _drawMeasurements(canvas, offsets);
    }
  }

  void _drawOpenings(Canvas canvas, List<Offset> offsets) {
    for (int i = 0; i < offsets.length; i++) {
      final nextIdx = (i + 1) % offsets.length;
      if (!isClosed && nextIdx == 0) break;

      final openings = wallOpenings[i];
      if (openings == null || openings.isEmpty) continue;

      final p1 = offsets[i];
      final p2 = offsets[nextIdx];

      final double segDx = p2.dx - p1.dx;
      final double segDy = p2.dy - p1.dy;
      final double canvasSegLen = sqrt(segDx * segDx + segDy * segDy);
      final double realSegLen = points[i].distanceTo(points[nextIdx % points.length]);

      if (realSegLen <= 0 || canvasSegLen <= 0) continue;
      final double scaleRatio = canvasSegLen / realSegLen;

      final double uX = segDx / canvasSegLen;
      final double uY = segDy / canvasSegLen;

      for (final op in openings) {
        final double startOnCanvas = op.distanceFromStart * scaleRatio;
        final double widthOnCanvas = op.width * scaleRatio;

        final Offset opStart = Offset(p1.dx + uX * startOnCanvas, p1.dy + uY * startOnCanvas);
        final Offset opEnd = Offset(opStart.dx + uX * widthOnCanvas, opStart.dy + uY * widthOnCanvas);

        canvas.drawLine(opStart, opEnd, _clearPaint);

        if (op.type == OpeningType.door) {
          canvas.drawLine(opStart, opEnd, _doorPaint);
          final Offset perp = Offset(-uY * widthOnCanvas, uX * widthOnCanvas);
          final Offset doorOpenEnd = opStart + perp;
          canvas.drawLine(opStart, doorOpenEnd, _doorPaint);
          final rect = Rect.fromCircle(center: opStart, radius: widthOnCanvas);
          canvas.drawArc(rect, atan2(uY, uX), pi / 2, false, _doorPaint);
        } else if (op.type == OpeningType.window) {
          canvas.drawLine(opStart, opEnd, _windowPaint);
        }
      }
    }
  }

  void _drawMeasurements(Canvas canvas, List<Offset> offsets) {
    final style = TextStyle(color: Colors.grey.shade800, fontSize: 11, fontWeight: FontWeight.bold);
    for (int i = 0; i < offsets.length - 1; i++) {
      _drawSegmentLabel(canvas, offsets[i], offsets[i + 1], points[i].distanceTo(points[i + 1]), style);
    }
    if (isClosed && offsets.length > 2) {
      _drawSegmentLabel(canvas, offsets.last, offsets.first, points.last.distanceTo(points.first), style);
    }
  }

  void _drawSegmentLabel(Canvas canvas, Offset p1, Offset p2, double distance, TextStyle style) {
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final textPainter = TextPainter(
      text: TextSpan(text: '${distance.toStringAsFixed(2)} m', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.drawRect(
      Rect.fromCenter(center: mid, width: textPainter.width + 6, height: textPainter.height + 2),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    textPainter.paint(canvas, Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.isClosed != isClosed ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.projection != projection;
}
