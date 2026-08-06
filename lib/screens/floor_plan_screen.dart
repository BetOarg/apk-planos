import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_notifier.dart';
import '../models/wall_opening.dart';
import '../utils/measurements.dart';
import '../utils/export_helper.dart';
import '../widgets/floor_plan_canvas.dart';

class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final scanState = context.watch<ScanNotifier>();
    final points = scanState.points;
    final isClosed = scanState.isClosed;
    final openings = scanState.wallOpenings;

    final perimeter = Measurements.calculatePerimeter(points, isClosed: isClosed);
    final area = isClosed ? Measurements.calculateArea(points) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano 2D Interactivo'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Perímetro: ${Measurements.formatMeters(perimeter)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Área: ${isClosed ? Measurements.formatSquareMeters(area) : "—"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Techo: ${scanState.ceilingHeight.toStringAsFixed(2)} m', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: InteractiveFloorPlan(
                points: points,
                wallOpenings: openings,
                isClosed: isClosed,
                northHeading: scanState.initialHeading,
                onPointUpdated: (idx, p) {
                  final ok = scanState.updatePoint(idx, p);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Movimiento inválido: genera intersección o trasmaladado corto.')),
                    );
                  }
                },
                onSegmentTap: (segmentIdx) => _showAddOpeningDialog(context, segmentIdx, scanState),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ExportHelper.exportAsImage(globalKey: _repaintKey, roomName: 'plano'),
                    icon: const Icon(Icons.image),
                    label: const Text('Exportar PNG'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ExportHelper.exportAsPDF(
                      points: points,
                      wallOpenings: openings,
                      isClosed: isClosed,
                      roomName: 'plano',
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar PDF'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOpeningDialog(BuildContext context, int segmentIndex, ScanNotifier scanState) {
    final points = scanState.points;
    if (points.length < 2) return;
    final nextIdx = (segmentIndex + 1) % points.length;
    if (!scanState.isClosed && nextIdx == 0) return;

    final maxSegmentLength = points[segmentIndex].distanceTo(points[nextIdx]);
    if (maxSegmentLength <= 0) return;

    OpeningType selectedType = OpeningType.door;
    double width = 0.90;
    double distance = ((maxSegmentLength - width) / 2).clamp(0.0, maxSegmentLength - width);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Añadir Elemento en Pared ${segmentIndex + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Longitud total del tramo: ${maxSegmentLength.toStringAsFixed(2)} m',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 16),
                  SegmentedButton<OpeningType>(
                    segments: const [
                      ButtonSegment(value: OpeningType.door, label: Text('Puerta'), icon: Icon(Icons.door_front_door)),
                      ButtonSegment(value: OpeningType.window, label: Text('Ventana'), icon: Icon(Icons.window)),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (val) {
                      setModalState(() {
                        selectedType = val.first;

                        // CORRECCIÓN PUNTO 12:
                        // Al cambiar de tipo, el ancho por defecto puede exceder la longitud
                        // del tramo (ej. ventana 1.20 m en pared de 0.90 m). Forzamos clamp.
                        final double defaultWidth =
                            selectedType == OpeningType.door ? 0.90 : 1.20;
                        width = defaultWidth.clamp(0.40, maxSegmentLength - 0.01);

                        // Recalcular distancia para que el elemento siga centrado
                        // y no exceda los límites del tramo.
                        distance = ((maxSegmentLength - width) / 2).clamp(0.0, maxSegmentLength - width);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Ancho del elemento: ${width.toStringAsFixed(2)} m'),
                  Slider(
                    // CORRECCIÓN PUNTO 12 (defensa adicional):
                    // El value del Slider nunca puede superar max.
                    value: width.clamp(0.40, maxSegmentLength > 0.40 ? maxSegmentLength : 0.40),
                    min: 0.40,
                    max: maxSegmentLength > 2.5 ? 2.5 : maxSegmentLength,
                    divisions: 21,
                    onChanged: (v) => setModalState(() {
                      width = v;
                      // Reajustar distancia si el ancho nuevo la desborda
                      distance = distance.clamp(0.0, (maxSegmentLength - width).clamp(0.0, double.infinity));
                    }),
                  ),
                  Text('Posición desde esquina inicio: ${distance.toStringAsFixed(2)} m'),
                  Slider(
                    // CORRECCIÓN PUNTO 12 (defensa adicional):
                    value: distance.clamp(
                      0.0,
                      (maxSegmentLength - width).clamp(0.01, maxSegmentLength),
                    ),
                    min: 0.0,
                    max: (maxSegmentLength - width).clamp(0.01, maxSegmentLength),
                    onChanged: (v) => setModalState(() => distance = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final opening = WallOpening(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          type: selectedType,
                          distanceFromStart: distance,
                          width: width,
                          height: selectedType == OpeningType.door ? 2.10 : 1.20,
                          elevation: selectedType == OpeningType.window ? 0.90 : 0.0,
                        );
                        scanState.addOpening(segmentIndex, opening);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Insertar en Pared'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
