import '../models/scan_point.dart';
import '../utils/ar_stability_filter.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

enum CaptureState { idle, sampling, stable, error }

class CaptureResult {
  final ScanPoint? point;
  final CaptureState state;
  final String? errorMessage;

  const CaptureResult._(this.point, this.state, this.errorMessage);

  factory CaptureResult.stable(ScanPoint point) =>
      CaptureResult._(point, CaptureState.stable, null);

  factory CaptureResult.error(String message) =>
      CaptureResult._(null, CaptureState.error, message);

  factory CaptureResult.sampling() =>
      const CaptureResult._(null, CaptureState.sampling, null);

  bool get isSuccess => state == CaptureState.stable && point != null;
}

class CaptureService {
  final ARStabilityFilter _stabilityFilter = ARStabilityFilter();
  bool _isCapturing = false;

  bool get isCapturing => _isCapturing;

  Future<CaptureResult> samplePoint({
    required Future<ScanPoint?> Function() hitTest,
    required Duration samplingDuration,
    required Duration sampleInterval,
  }) async {
    if (_isCapturing) {
      return CaptureResult.error('Captura en progreso');
    }

    _isCapturing = true;
    _stabilityFilter.reset();

    final stopwatch = Stopwatch()..start();
    ScanPoint? stablePoint;

    while (stopwatch.elapsed < samplingDuration && stablePoint == null) {
      final sample = await hitTest();
      if (sample != null) {
        final vec = vm.Vector3(sample.x, sample.y, sample.z);
        final filtered = _stabilityFilter.feed(vec);
        if (filtered != null && _stabilityFilter.isStable) {
          stablePoint = sample;
        }
      }
      await Future.delayed(sampleInterval);
    }

    _isCapturing = false;

    if (stablePoint == null) {
      return CaptureResult.error('Inestabilidad detectada. Repite la captura.');
    }

    return CaptureResult.stable(stablePoint);
  }

  void cancel() {
    _isCapturing = false;
  }
}
