import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/scan_point.dart';
import '../models/wall_opening.dart';
import '../utils/measurements.dart';

class FloorPlanPdfPainter {
  final List<ScanPoint> points;
  final Map<int, List<WallOpening>> wallOpenings;
  final bool isClosed;

  FloorPlanPdfPainter({
    required this.points,
    required this.wallOpenings,
    required this.isClosed,
  });

  pw.Document generateDocument() {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.SizedBox(
              width: 500,
              height: 500,
              child: pw.CustomPaint(
                size: const PdfPoint(500, 500),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  _drawFloorPlan(canvas, size);
                },
              ),
            ),
          );
        },
      ),
    );
    return doc;
  }

  void _drawFloorPlan(PdfGraphics canvas, PdfPoint size) {
    if (points.length < 2) return;

    final projection = Measurements.projectToCanvas2D(
      points,
      canvasWidth: size.x,
      canvasHeight: size.y,
      padding: 40.0,
    );

    final projected = projection.projected;
    if (projected.isEmpty) return;

    final offsets = projected.map((p) => PdfPoint(p.offset.dx, p.offset.dy)).toList();

    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(2.0);
    for (int i = 0; i < offsets.length - 1; i++) {
      _drawLine(canvas, offsets[i], offsets[i + 1]);
    }
    if (isClosed && offsets.length > 2) {
      _drawLine(canvas, offsets.last, offsets.first);
    }
    canvas.strokePath();

    _drawOpenings(canvas, offsets, projection.scale);

    canvas.setFillColor(PdfColors.red);
    for (final pt in offsets) {
      canvas.drawEllipse(pt.x - 2, pt.y - 2, 4, 4);
      canvas.fillPath();
    }
  }

  void _drawLine(PdfGraphics canvas, PdfPoint a, PdfPoint b) {
    canvas.moveTo(a.x, a.y);
    canvas.lineTo(b.x, b.y);
  }

  void _drawOpenings(PdfGraphics canvas, List<PdfPoint> offsets, double scale) {
    for (int i = 0; i < offsets.length; i++) {
      final nextIdx = (i + 1) % offsets.length;
      if (!isClosed && nextIdx == 0) break;

      final openings = wallOpenings[i];
      if (openings == null || openings.isEmpty) continue;

      final p1 = offsets[i];
      final p2 = offsets[nextIdx];
      final segDx = p2.x - p1.x;
      final segDy = p2.y - p1.y;
      final canvasSegLen = sqrt(segDx * segDx + segDy * segDy);
      final realSegLen = points[i].distanceTo(points[nextIdx % points.length]);

      if (realSegLen <= 0 || canvasSegLen <= 0) continue;
      final ratio = canvasSegLen / realSegLen;
      final uX = segDx / canvasSegLen;
      final uY = segDy / canvasSegLen;

      for (final op in openings) {
        final startDist = op.distanceFromStart * ratio;
        final widthDist = op.width * ratio;
        final start = PdfPoint(p1.x + uX * startDist, p1.y + uY * startDist);
        final end = PdfPoint(start.x + uX * widthDist, start.y + uY * widthDist);

        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(3.0);
        _drawLine(canvas, start, end);
        canvas.strokePath();

        if (op.type == OpeningType.door) {
          canvas.setStrokeColor(PdfColor(21, 101, 192));
          canvas.setLineWidth(1.5);
          _drawLine(canvas, start, end);
          canvas.strokePath();

          final perpX = -uY * widthDist;
          final perpY = uX * widthDist;
          final arcEnd = PdfPoint(start.x + perpX, start.y + perpY);
          _drawLine(canvas, start, arcEnd);
          canvas.strokePath();

          _drawArc(canvas, start, widthDist, atan2(uY, uX), pi / 2,
              PdfColor(21, 101, 192), 1.5);
        } else {
          canvas.setStrokeColor(PdfColor(0, 131, 143));
          canvas.setLineWidth(3.0);
          _drawLine(canvas, start, end);
          canvas.strokePath();
        }
      }
    }
  }

  void _drawArc(PdfGraphics canvas, PdfPoint center, double radius,
      double startAngle, double sweep, PdfColor color, double lineWidth) {
    const segments = 12;
    final angleStep = sweep / segments;
    canvas.setStrokeColor(color);
    canvas.setLineWidth(lineWidth);

    for (int i = 0; i <= segments; i++) {
      final angle = startAngle + angleStep * i;
      final pt = PdfPoint(
        center.x + radius * cos(angle),
        center.y + radius * sin(angle),
      );
      if (i == 0) {
        canvas.moveTo(pt.x, pt.y);
      } else {
        canvas.lineTo(pt.x, pt.y);
      }
    }
    canvas.strokePath();
  }
}
