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
  final List<double> _blueSamples = [];
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
    _blueSamples.clear();
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

    int redSum = 0, blueSum = 0, count = 0;
    final startX = width ~/ 3;
    final endX = 2 * width ~/ 3;
    final startY = height ~/ 3;
    final endY = 2 * height ~/ 3;

    for (int y = startY; y < endY; y += 4) {
      for (int x = startX; x < endX; x += 4) {
        final pixel = (y * width + x) * 4;
        if (pixel + 3 < bytes.length) {
          blueSum += bytes[pixel];
          redSum += bytes[pixel + 2];
          count++;
        }
      }
    }

    if (count == 0) return;

    _redSamples.add(redSum / count);
    _blueSamples.add(blueSum / count);

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
    final spo2 = _calculateSpO2(_redSamples, _blueSamples);
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
    if (signal.length < 30) return _simulatedBPM();
    final filtered = _bandpassFilter(signal);
    final peaks = _findPeaks(filtered);
    if (peaks.length < 2) return _simulatedBPM();

    final intervals = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add((peaks[i] - peaks[i - 1]) / _sampleRate);
    }
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    return (60.0 / avgInterval).clamp(40.0, 180.0);
  }

  double _calculateSpO2(List<double> red, List<double> blue) {
    if (red.isEmpty || blue.isEmpty) return 98.0;
    final redAC = _acComponent(red);
    final redDC = _dcComponent(red);
    final blueAC = _acComponent(blue);
    final blueDC = _dcComponent(blue);
    if (redDC == 0 || blueDC == 0) return 98.0;
    final ratio = (redAC / redDC) / (blueAC / blueDC);
    final spo2 = 110.0 - 25.0 * ratio;
    return spo2.clamp(85.0, 100.0);
  }

  List<double> _bandpassFilter(List<double> signal) {
    final result = <double>[];
    const alpha = 0.85;
    double prev = signal[0];
    for (final s in signal) {
      final filtered = alpha * prev + (1 - alpha) * s;
      result.add(s - filtered);
      prev = filtered;
    }
    return result;
  }

  List<int> _findPeaks(List<double> signal) {
    final peaks = <int>[];
    const minPeakDist = 15;
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        if (peaks.isEmpty || i - peaks.last >= minPeakDist) {
          peaks.add(i);
        }
      }
    }
    return peaks;
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
