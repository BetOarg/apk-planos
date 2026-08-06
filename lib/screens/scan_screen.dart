import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ar_scan_controller.dart';
import '../providers/scan_notifier.dart';
import '../widgets/ar_scan_view.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final ARScanController _arController;

  @override
  void initState() {
    super.initState();
    _arController = ARScanController();
  }

  @override
  void dispose() {
    _arController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de Habitación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            // CORRECCIÓN PUNTO 11: sincronizar undo visual AR + estado de negocio
            onPressed: () {
              final notifier = context.read<ScanNotifier>();
              if (notifier.points.isNotEmpty) {
                notifier.undoLastPoint();
                _arController.removeLastVisualMarker();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            // CORRECCIÓN PUNTO 11: sincronizar clear visual AR + estado de negocio
            onPressed: () {
              context.read<ScanNotifier>().clearPoints();
              _arController.clearVisualMarkers();
            },
          ),
        ],
      ),
      body: Consumer<ScanNotifier>(
        builder: (context, scanNotifier, child) {
          return Stack(
            children: [
              ARScanView(
                controller: _arController,
                existingPoints: scanNotifier.points,
              ),
              if (scanNotifier.errorMessage != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      scanNotifier.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Positioned(
                bottom: 24,
                left: 24,
                child: Chip(
                  label: Text('Esquinas: ${scanNotifier.points.length}'),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ScanNotifier>(
        builder: (context, scanNotifier, child) {
          return FloatingActionButton.extended(
            onPressed: () async {
              // CORRECCIÓN PUNTO 11:
              // El controller ya NO guarda puntos internamente.
              // Solo filtra AR y devuelve el punto estable para que el
              // ScanNotifier (fuente de verdad única) lo persista.
              final captured = await _arController.capturePoint();
              if (captured != null) {
                scanNotifier.addPoint(captured);
              }
            },
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Marcar esquina'),
          );
        },
      ),
    );
  }
}
