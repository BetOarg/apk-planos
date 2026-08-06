import 'dart:math';
import 'package:flutter/material.dart';
import '../models/scan_point.dart';
import '../models/projected_point.dart';

class Measurements {
  static double calculatePerimeter(List<ScanPoint> points, {bool isClosed = true}) {
    if (points.length < 2) return 0.0;
    double perimeter = 0.0;
    final limit = isClosed ? points.length : points.length - 1;
    for (int i = 0; i < limit; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      perimeter += _distance2D(p1, p2);
    }
    return perimeter;
  }

  static double calculateArea(List<ScanPoint> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].x * points[j].z;
      area -= points[j].x * points[i].z;
    }
    return (area.abs() / 2.0);
  }

  static String formatMeters(double value) {
    return '${value.toStringAsFixed(2)} m';
  }

  static String formatSquareMeters(double value) {
    return '${value.toStringAsFixed(2)} m²';
  }

  static double _distance2D(ScanPoint a, ScanPoint b) {
    final dx = b.x - a.x;
    final dz = b.z - a.z;
    return sqrt(dx * dx + dz * dz);
  }

  static ProjectionResult projectToCanvas2D(
    List<ScanPoint> points, {
    required double canvasWidth,
    required double canvasHeight,
    double padding = 40.0,
  }) {
    if (points.isEmpty) {
      return const ProjectionResult(
        projected: [],
        scale: 1.0,
        bounds: Rect.zero,
      );
    }

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minZ = double.infinity, maxZ = double.negativeInfinity;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.z < minZ) minZ = p.z;
      if (p.z > maxZ) maxZ = p.z;
    }

    final rangeX = maxX - minX;
    final rangeZ = maxZ - minZ;

    final availableW = canvasWidth - 2 * padding;
    final availableH = canvasHeight - 2 * padding;

    final scaleX = rangeX > 0 ? availableW / rangeX : 1.0;
    final scaleZ = rangeZ > 0 ? availableH / rangeZ : 1.0;
    final scale = scaleX < scaleZ ? scaleX : scaleZ;

    final offsetX = (canvasWidth - rangeX * scale) / 2 - minX * scale;
    final offsetY = (canvasHeight - rangeZ * scale) / 2 - minZ * scale;

    final List<ProjectedPoint> projected = [];
    for (final p in points) {
      projected.add(ProjectedPoint(
        original: p,
        offset: Offset(p.x * scale + offsetX, canvasHeight - (p.z * scale + offsetY)),
        scale: scale,
      ));
    }

    final bounds = Rect.fromLTRB(
      offsetX + minX * scale,
      canvasHeight - (offsetY + maxZ * scale),
      offsetX + maxX * scale,
      canvasHeight - (offsetY + minZ * scale),
    );

    return ProjectionResult(
      projected: projected,
      scale: scale,
      bounds: bounds,
    );
  }
}
