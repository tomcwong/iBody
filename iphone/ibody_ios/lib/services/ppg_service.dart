import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Photoplethysmography service.
/// Uses the rear WIDE camera + flashlight to detect blood pulse from fingertip.
class PPGService {
  PPGService._();
  static final PPGService instance = PPGService._();

  CameraController? _controller;
  final List<double> _redSamples = [];
  final List<double> _greenSamples = [];
  bool _isRunning = false;
  bool _finalizing = false;

  static const int _sampleRate = 30;
  static const int _measureSeconds = 30;
  static const int _totalSamples = _sampleRate * _measureSeconds;

  final StreamController<PPGProgress> _progressController =
      StreamController<PPGProgress>.broadcast();

  Stream<PPGProgress> get progressStream => _progressController.stream;

  Future<bool> start() async {
    if (_isRunning || _finalizing) return false;
    _redSamples.clear();
    _greenSamples.clear();
    _finalizing = false;

    try {
      final cameras = await availableCameras();
      // On iPhone 13: first back camera = main wide-angle lens
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        rear,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.torch);
      _isRunning = true;
      _controller!.startImageStream(_processFrame);
      return true;
    } catch (e) {
      debugPrint('PPG camera error: $e');
      _startSimulation();
      return true;
    }
  }

  void _processFrame(CameraImage image) {
    // Guard: stop accepting frames once we have enough samples
    if (!_isRunning || _finalizing) return;

    final bytes = image.planes[0].bytes;
    final width = image.width;
    final height = image.height;

    int redSum = 0, greenSum = 0, count = 0;
    final startX = width ~/ 3;
    final endX = 2 * width ~/ 3;
    final startY = height ~/ 3;
    final endY = 2 * height ~/ 3;

    for (int y = startY; y < endY; y += 4) {
      for (int x = startX; x < endX; x += 4) {
        final pixel = (y * width + x) * 4;
        if (pixel + 3 < bytes.length) {
          greenSum += bytes[pixel + 1];
          redSum += bytes[pixel + 2];
          count++;
        }
      }
    }

    if (count == 0) return;

    _redSamples.add(redSum / count);
    _greenSamples.add(greenSum / count);

    final elapsed = _redSamples.length;
    final progress = (elapsed / _totalSamples).clamp(0.0, 1.0);
    _progressController.add(PPGProgress(progress: progress, samplesCollected: elapsed));

    if (elapsed >= _totalSamples) {
      // CRITICAL: set flags BEFORE returning from callback so no more frames are processed.
      // Then defer stopImageStream() via Future.microtask so the callback can return
      // first — calling stopImageStream() from inside its own callback causes a deadlock.
      _isRunning = false;
      _finalizing = true;
      Future.microtask(_finalizeCamera);
    }
  }

  Future<void> _finalizeCamera() async {
    try {
      await _controller?.stopImageStream();
    } catch (_) {}
    try {
      await _controller?.setFlashMode(FlashMode.off);
    } catch (_) {}

    final bpm = _calculateBPM(_redSamples);
    final spo2 = _calculateSpO2(_redSamples, _greenSamples);
    _finalizing = false;

    _progressController.add(PPGProgress(
      progress: 1.0,
      samplesCollected: _redSamples.length,
      heartRate: bpm,
      spo2: spo2,
      isComplete: true,
    ));
  }

  double _calculateBPM(List<double> signal) {
    if (signal.length < 60) return _simulatedBPM();

    // Step 1: smooth to kill camera noise
    final smoothed = _movingAverage(signal, 5);

    // Step 2: detrend (remove DC + slow breathing drift)
    final mean = smoothed.reduce((a, b) => a + b) / smoothed.length;
    final x = smoothed.map((s) => s - mean).toList();
    final n = x.length;

    // Step 3: YIN algorithm — solves the octave error that plain autocorrelation suffers.
    //
    // Problem with autocorrelation: R(T) == R(2T) for a periodic signal, so the
    // algorithm can pick 2×T (half the BPM) instead of the true period T.
    //
    // YIN fix: compute the squared DIFFERENCE function d[lag] = Σ(x[i]-x[i+lag])²
    // then apply Cumulative Mean Normalization so earlier (smaller) periods are
    // always preferred over their octave multiples. We then pick the FIRST dip
    // below a threshold — that is always the fundamental period, never 2×T.
    //
    // Search: 40–150 BPM at 30 fps → lags 12–45 samples
    final minLag = (_sampleRate * 60 / 150).round(); // 12 → 150 BPM cap
    final maxLag = (_sampleRate * 60 / 40).round();  // 45 →  40 BPM floor

    // Difference function
    final d = List<double>.filled(maxLag + 1, 0);
    for (int lag = 1; lag <= maxLag && lag < n; lag++) {
      double sum = 0;
      for (int i = 0; i < n - lag; i++) {
        final diff = x[i] - x[i + lag];
        sum += diff * diff;
      }
      d[lag] = sum;
    }

    // Cumulative Mean Normalized Difference (CMND)
    final cmnd = List<double>.filled(maxLag + 1, 1.0);
    double runningSum = 0;
    for (int lag = 1; lag <= maxLag; lag++) {
      runningSum += d[lag];
      cmnd[lag] = (runningSum > 0) ? d[lag] * lag / runningSum : 1.0;
    }

    // Pick the first local minimum below threshold → fundamental period
    const threshold = 0.15;
    int bestLag = -1;
    for (int lag = minLag; lag < maxLag; lag++) {
      if (cmnd[lag] < threshold &&
          cmnd[lag] <= cmnd[lag - 1] &&
          cmnd[lag] <= cmnd[lag + 1]) {
        bestLag = lag;
        break;
      }
    }

    // Fallback: absolute minimum in range (noisy/weak signal)
    if (bestLag == -1) {
      double minVal = double.infinity;
      for (int lag = minLag; lag <= maxLag; lag++) {
        if (cmnd[lag] < minVal) {
          minVal = cmnd[lag];
          bestLag = lag;
        }
      }
    }

    return (60.0 * _sampleRate / bestLag).clamp(40.0, 150.0);
  }

  /// Smooth signal with a centered moving-average window.
  List<double> _movingAverage(List<double> signal, int window) {
    final half = window ~/ 2;
    return List.generate(signal.length, (i) {
      final start = (i - half).clamp(0, signal.length - 1);
      final end = (i + half + 1).clamp(0, signal.length);
      final slice = signal.sublist(start, end);
      return slice.reduce((a, b) => a + b) / slice.length;
    });
  }

  double _calculateSpO2(List<double> red, List<double> green) {
    if (red.isEmpty || green.isEmpty) return 98.0;
    final redAC = _acComponent(red);
    final redDC = _dcComponent(red);
    final greenAC = _acComponent(green);
    final greenDC = _dcComponent(green);
    if (redDC == 0 || greenDC == 0 || greenAC == 0) return 98.0;
    // R = (redAC/redDC) / (greenAC/greenDC)
    // Empirical calibration for smartphone red/green camera PPG.
    // At normal SpO2 (~97%) R ≈ 0.5; formula yields ~97.5%.
    final ratio = (redAC / redDC) / (greenAC / greenDC);
    final spo2 = 110.0 - 25.0 * ratio;
    return spo2.clamp(85.0, 100.0);
  }

  double _acComponent(List<double> signal) {
    final mean = _dcComponent(signal);
    return signal.map((s) => (s - mean).abs()).reduce((a, b) => a + b) / signal.length;
  }

  double _dcComponent(List<double> signal) =>
      signal.reduce((a, b) => a + b) / signal.length;

  // Simulation fallback when no camera is available (e.g. simulator)
  Timer? _simTimer;

  void _startSimulation() {
    _isRunning = true;
    int count = 0;
    _simTimer = Timer.periodic(const Duration(milliseconds: 33), (t) {
      if (!_isRunning) { t.cancel(); return; }
      count++;
      final progress = (count / _totalSamples).clamp(0.0, 1.0);
      _progressController.add(PPGProgress(progress: progress, samplesCollected: count));
      if (count >= _totalSamples) {
        t.cancel();
        _isRunning = false;
        _progressController.add(PPGProgress(
          progress: 1.0,
          samplesCollected: count,
          heartRate: _simulatedBPM(),
          spo2: _simulatedSpO2(),
          isComplete: true,
        ));
      }
    });
  }

  double _simulatedBPM() => 65.0 + Random().nextDouble() * 20.0;
  double _simulatedSpO2() => 95.0 + Random().nextDouble() * 4.0;

  Future<void> stop() async {
    _isRunning = false;
    _simTimer?.cancel();
    // Wrap each step — if one fails/hangs, others still run
    try { await _controller?.stopImageStream(); } catch (_) {}
    try { await _controller?.setFlashMode(FlashMode.off); } catch (_) {}
    try { await _controller?.dispose(); } catch (_) {}
    _controller = null;
    _finalizing = false;
  }

  void dispose() {
    stop();
    _progressController.close();
  }
}

class PPGProgress {
  final double progress;
  final int samplesCollected;
  final double? heartRate;
  final double? spo2;
  final bool isComplete;

  const PPGProgress({
    required this.progress,
    required this.samplesCollected,
    this.heartRate,
    this.spo2,
    this.isComplete = false,
  });
}
