import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/scan_point.dart';
import '../models/wall_opening.dart';
import 'pdf_floor_plan_painter.dart';
import 'measurements.dart';

class ExportHelper {
  static Future<File> exportAsImage({
    required GlobalKey globalKey,
    String? roomName,
  }) async {
    final boundary = globalKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('No render object');

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final name = roomName != null ? '${roomName}_plano.png' : 'floor_plan.png';
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  static Future<File> exportAsPDF({
    required List<ScanPoint> points,
    Map<int, List<WallOpening>>? wallOpenings,
    required bool isClosed,
    String? roomName,
  }) async {
    final area = isClosed ? Measurements.calculateArea(points) : 0.0;
    final perimeter = Measurements.calculatePerimeter(points);

    final painter = FloorPlanPdfPainter(
      points: points,
      wallOpenings: wallOpenings ?? {},
      isClosed: isClosed,
    );

    final doc = painter.generateDocument();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  roomName ?? 'Plano de Planta',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['Métrica', 'Valor'],
                  data: [
                    ['Área', '${area.toStringAsFixed(2)} m²'],
                    ['Perímetro', '${perimeter.toStringAsFixed(2)} m'],
                    ['Vértices', '${points.length}'],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                ),
              ],
            ),
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final name = roomName != null ? '${roomName}_plano.pdf' : 'floor_plan.pdf';
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? 'Plano de planta',
    );
  }
}
