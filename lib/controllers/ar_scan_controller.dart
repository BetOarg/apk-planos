import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../models/scan_point.dart';
import '../utils/ar_stability_filter.dart';
import '../utils/measurements.dart';

class ARScanController extends ChangeNotifier {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _objectManager;
  final ARStabilityFilter _stabilityFilter = ARStabilityFilter(emaAlpha: 0.3);
  final List<ScanPoint> _scanPoints = [];
  final List<ARNode> _visualMarkers = [];
  bool _isPointStable = false;
  bool _planeDetected = false;
  vm.Vector3? _lastFilteredPosition;

  List<ScanPoint> get scanPoints => List.unmodifiable(_scanPoints);
  bool get isPointStable => _isPointStable;
  bool get planeDetected => _planeDetected;
  vm.Vector3? get lastFilteredPosition => _lastFilteredPosition;
  int get pointCount => _scanPoints.length;
  double get perimeter => Measurements.calculatePerimeter(_scanPoints);
  double get area => Measurements.calculateArea(_scanPoints);

  String get statusMessage {
    if (!_planeDetected) return 'Buscando superficie... Mueve el dispositivo';
    if (!_isPointStable) return 'Punto inestable. Mantén el cursor quieto';
    if (_scanPoints.isEmpty) return 'Toca CAPTURAR para el primer vértice';
    return 'Vértices: $pointCount | Listo para capturar';
  }

  Future<void> onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) async {
    _arSessionManager = arSessionManager;
    _objectManager = arObjectManager;

    await _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handlePans: false,
      handleRotation: false,
    );
    await _objectManager!.onInitialize();

    _arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
    notifyListeners();
  }

  void _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) {
    if (hitTestResults.isEmpty) return;
    final hit = hitTestResults.first;
    final rawPos = vm.Vector3(
      hit.worldTransform.getColumn(3).x,
      hit.worldTransform.getColumn(3).y,
      hit.worldTransform.getColumn(3).z,
    );

    final filtered = _stabilityFilter.filter(rawPos);
    if (filtered != null) {
      _lastFilteredPosition = filtered;
      _isPointStable = _stabilityFilter.isStable;
      if (!_planeDetected) _planeDetected = true;
      notifyListeners();
    }
  }

  Future<ScanPoint?> capturePoint() async {
    if (_lastFilteredPosition == null || !_isPointStable) return null;

    final point = ScanPoint(
      x: _lastFilteredPosition!.x,
      y: _lastFilteredPosition!.y,
      z: _lastFilteredPosition!.z,
      timestamp: DateTime.now(),
    );
    _scanPoints.add(point);
    await _addVisualMarker(_lastFilteredPosition!);
    notifyListeners();
    return point;
  }

  void undoLastPoint() {
    if (_scanPoints.isEmpty) return;
    _scanPoints.removeLast();
    notifyListeners();
  }

  Future<void> removeLastVisualMarker() async {
    if (_visualMarkers.isNotEmpty && _objectManager != null) {
      final node = _visualMarkers.removeLast();
      await _objectManager!.removeNode(node);
    }
  }

  Future<void> clearVisualMarkers() async {
    if (_objectManager != null) {
      for (final node in _visualMarkers) {
        await _objectManager!.removeNode(node);
      }
    }
    _visualMarkers.clear();
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  Future<void> _addVisualMarker(vm.Vector3 position) async {
    if (_objectManager == null) return;
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/models/sphere.gltf",
      scale: vm.Vector3(0.05, 0.05, 0.05),
      position: position,
      rotation: vm.Vector4(1, 0, 0, 0),
    );
    await _objectManager!.addNode(node);
    _visualMarkers.add(node);
  }
}
