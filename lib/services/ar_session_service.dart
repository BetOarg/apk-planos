import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';

class ARSessionService {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  
  // ignore: unused_field
  ARAnchorManager? _anchorManager;
  // ignore: unused_field
  ARLocationManager? _locationManager;

  ARSessionManager? get sessionManager => _sessionManager;
  ARObjectManager? get objectManager => _objectManager;

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;
    _locationManager = locationManager;

    _sessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
      showAnimatedGuide: false,
    );

    _objectManager?.onInitialize();
  }

  void updatePlaneDetection(bool enabled) {
    _sessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: enabled,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
      showAnimatedGuide: false,
    );
  }

  void dispose() {
    _sessionManager?.dispose();
    _sessionManager = null;
    _objectManager = null;
    _anchorManager = null;
    _locationManager = null;
  }
}