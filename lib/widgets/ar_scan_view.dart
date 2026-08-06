import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import '../controllers/ar_scan_controller.dart';
import '../models/scan_point.dart';
import 'ar_line_overlay.dart';

class ARScanView extends StatefulWidget {
  final ARScanController controller;
  final List<ScanPoint> existingPoints;

  const ARScanView({
    super.key,
    required this.controller,
    required this.existingPoints,
  });

  @override
  State<ARScanView> createState() => _ARScanViewState();
}

class _ARScanViewState extends State<ARScanView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant ARScanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Stack(
      children: [
        ARView(
          onARViewCreated: controller.onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontal,
        ),
        ARLineOverlay(
          points: widget.existingPoints,
          isClosed: false, // En pantalla de escaneo el polígono aún no está cerrado
        ),
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  // CORRECCIÓN PUNTO 6: planeDetected ahora existe en el controller
                  controller.planeDetected
                      ? Icons.check_circle
                      : Icons.screen_search_desktop_outlined,
                  color: controller.planeDetected
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    // CORRECCIÓN PUNTO 6: statusMessage ahora existe en el controller
                    controller.statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
