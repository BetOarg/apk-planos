import 'package:flutter/material.dart';
import '../models/scan_point.dart';

/// Representa un punto 3D proyectado a coordenadas 2D de canvas.
class ProjectedPoint {
  final ScanPoint original;
  final Offset offset;
  final double scale;

  const ProjectedPoint({
    required this.original,
    required this.offset,
    required this.scale,
  });
}

/// Resultado completo de una proyección 2D con escala y bounds.
class ProjectionResult {
  final List<ProjectedPoint> projected;
  final double scale;
  final Rect bounds;

  const ProjectionResult({
    required this.projected,
    required this.scale,
    required this.bounds,
  });
}
