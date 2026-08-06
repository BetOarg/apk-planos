import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../models/scan_point.dart';
import '../models/wall_opening.dart';
import '../services/ar_session_service.dart';
import '../utils/ar_stability_filter.dart';
import '../utils/scan_validator.dart';

/// Fuente de verdad única del estado del escaneo.
///
/// Mantiene la lista de puntos, openings, flags de cierre y validaciones.
/// NO conoce detalles de AR nativo; recibe ScanPoint ya procesados.
class ScanNotifier extends ChangeNotifier {
  final ARSessionService _arService = ARSessionService();
  final ARStabilityFilter _stabilityFilter = ARStabilityFilter();

  final List<ScanPoint> _points = [];
  final Map<int, List<WallOpening>> _wallOpenings = {};
  bool _isProcessing = false;
  bool _isClosed = false;
  String? _errorMessage;
  double _initialHeading = 0.0;
  double _ceilingHeight = 2.5;

  List<ScanPoint> get points => List.unmodifiable(_points);
  Map<int, List<WallOpening>> get wallOpenings => Map.unmodifiable(_wallOpenings);
  bool get isProcessing => _isProcessing;
  bool get isClosed => _isClosed;
  String? get errorMessage => _errorMessage;
  double get initialHeading => _initialHeading;
  double get ceilingHeight => _ceilingHeight;
  ARSessionService get arService => _arService;

  void addPoint(ScanPoint rawPoint) {
    _errorMessage = null;

    final rawVector = vm.Vector3(rawPoint.x, rawPoint.y, rawPoint.z);
    final filteredVector = _stabilityFilter.filter(rawVector);
    if (filteredVector == null) {
      _errorMessage = "Punto descartado por inestabilidad del sensor AR";
      notifyListeners();
      return;
    }

    final filteredPoint = ScanPoint.fromCoordinates(
      filteredVector.x,
      filteredVector.y,
      filteredVector.z,
    );

    final validation = ScanValidator.validateNewPoint(filteredPoint, _points);
    if (!validation.isValid) {
      _errorMessage = validation.errorMessage ?? "El punto no cumple con las reglas de escaneo de la habitación";
      notifyListeners();
      return;
    }

    if (validation.warningMessage != null && validation.suggestedPoint != null) {
      _points.add(validation.suggestedPoint!);
      _isClosed = true;
    } else {
      _points.add(filteredPoint);
    }

    notifyListeners();
  }

  /// Elimina el último punto de la lista de negocio.
  /// El marcador visual AR correspondiente debe eliminarse desde el UI
  /// llamando a [ARScanController.removeLastVisualMarker].
  void undoLastPoint() {
    if (_points.isEmpty) return;
    _points.removeLast();
    _errorMessage = null;
    notifyListeners();
  }

  bool updatePoint(int index, ScanPoint updatedPoint) {
    if (index < 0 || index >= _points.length) return false;

    final validation = ScanValidator.validatePointUpdate(
      index,
      updatedPoint,
      _points,
      _isClosed,
    );

    if (!validation.isValid) {
      _errorMessage = validation.errorMessage ?? "Movimiento inválido";
      notifyListeners();
      return false;
    }

    _points[index] = updatedPoint;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void addOpening(int segmentIndex, WallOpening opening) {
    _wallOpenings.putIfAbsent(segmentIndex, () => []);
    _wallOpenings[segmentIndex]!.add(opening);
    notifyListeners();
  }

  void removeOpening(int segmentIndex, String openingId) {
    final list = _wallOpenings[segmentIndex];
    if (list == null) return;
    list.removeWhere((o) => o.id == openingId);
    if (list.isEmpty) _wallOpenings.remove(segmentIndex);
    notifyListeners();
  }

  void setClosed(bool value) {
    if (_isClosed == value) return;
    _isClosed = value;
    notifyListeners();
  }

  void setCeilingHeight(double height) {
    _ceilingHeight = height;
    notifyListeners();
  }

  void setInitialHeading(double heading) {
    _initialHeading = heading;
    notifyListeners();
  }

  void clearPoints() {
    _points.clear();
    _wallOpenings.clear();
    _isClosed = false;
    _errorMessage = null;
    _stabilityFilter.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _arService.dispose();
    super.dispose();
  }
}
