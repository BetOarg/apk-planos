import 'dart:math';

/// Representa un vértice 3D en el espacio AR (esquina de una habitación)
class ScanPoint {
  final double x; // Metro X
  final double y; // Altura / Cota
  final double z; // Metro Z
  final DateTime timestamp;

  const ScanPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  factory ScanPoint.fromARVector(List<double> vector) {
    return ScanPoint(
      x: vector[0],
      y: vector[1],
      z: vector[2],
      timestamp: DateTime.now(),
    );
  }

  factory ScanPoint.fromCoordinates(double x, double y, double z) {
    return ScanPoint(
      x: x,
      y: y,
      z: z,
      timestamp: DateTime.now(),
    );
  }

  ScanPoint copyWith({double? x, double? y, double? z, DateTime? timestamp}) {
    return ScanPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScanPoint.fromJson(Map<String, dynamic> json) {
    return ScanPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Distancia euclidiana plana (XZ)
  double distanceTo(ScanPoint other) {
    final dx = other.x - x;
    final dz = other.z - z;
    return sqrt(dx * dx + dz * dz);
  }

  /// Distancia euclidiana 3D
  double distanceTo3D(ScanPoint other) {
    final dx = other.x - x;
    final dy = other.y - y;
    final dz = other.z - z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  String toString() => 'ScanPoint(x: ${x.toStringAsFixed(3)}, z:${z.toStringAsFixed(3)})';
}
