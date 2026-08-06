enum OpeningType { door, window }

class WallOpening {
  final String id;
  final OpeningType type;
  final double distanceFromStart; // En metros desde el primer vértice del tramo
  final double width; // Ancho del elemento en metros
  final double height; // Altura en metros
  final double elevation; // Altura desde el suelo (0.0 para puertas)

  const WallOpening({
    required this.id,
    required this.type,
    required this.distanceFromStart,
    this.width = 0.90,
    this.height = 2.10,
    this.elevation = 0.0,
  });

  WallOpening copyWith({
    String? id,
    OpeningType? type,
    double? distanceFromStart,
    double? width,
    double? height,
    double? elevation,
  }) {
    return WallOpening(
      id: id ?? this.id,
      type: type ?? this.type,
      distanceFromStart: distanceFromStart ?? this.distanceFromStart,
      width: width ?? this.width,
      height: height ?? this.height,
      elevation: elevation ?? this.elevation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'distanceFromStart': distanceFromStart,
        'width': width,
        'height': height,
        'elevation': elevation,
      };

  factory WallOpening.fromJson(Map<String, dynamic> json) {
    return WallOpening(
      id: json['id'],
      type: OpeningType.values.byName(json['type']),
      distanceFromStart: (json['distanceFromStart'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
    );
  }
}
