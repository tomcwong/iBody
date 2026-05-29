import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/vital_reading.dart';
import '../../providers/health_provider.dart';
import '../../services/ppg_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trend_chart.dart';
import '../../widgets/vital_gauge.dart';

class HeartRateScreen extends ConsumerStatefulWidget {
  const HeartRateScreen({super.key});

  @override
  ConsumerState<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends ConsumerState<HeartRateScreen> {
  bool _measuring = false;
  double _progress = 0;
  double? _resultBpm;
  StreamSubscription? _sub;
  String? _errorMessage;

  Future<void> _startMeasurement() async {
    setState(() {
      _measuring = true;
      _progress = 0;
      _resultBpm = null;
      _errorMessage = null;
    });
    await WakelockPlus.enable();

    final ok = await PPGService.instance.start();
    if (!ok) {
      setState(() {
        _measuring = false;
        _errorMessage = 'Camera unavailable. Please allow camera access.';
      });
      await WakelockPlus.disable();
      return;
    }

    _sub = PPGService.instance.progressStream.listen((p) {
      if (!mounted) return;
      setState(() => _progress = p.progress);
      if (p.isComplete && p.heartRate != null) {
        _onComplete(p.heartRate!);
      }
    });
  }

  Future<void> _onComplete(double bpm) async {
    await WakelockPlus.disable();
    _sub?.cancel();
    await PPGService.instance.stop();

    final reading = VitalReading(
      id: const Uuid().v4(),
      type: VitalType.heartRate,
      value: bpm,
      timestamp: DateTime.now(),
    );
    await ref.read(healthProvider.notifier).saveReading(reading);

    if (mounted) {
      setState(() {
        _measuring = false;
        _resultBpm = bpm;
      });
    }
  }

  Future<void> _stopMeasurement() async {
    _sub?.cancel();
    await PPGService.instance.stop();
    await WakelockPlus.disable();
    setState(() => _measuring = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    PPGService.instance.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final history = health.history[VitalType.heartRate] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Heart Rate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Gauge
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.heartRed.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_measuring)
                    _LiveMeasurementView(progress: _progress)
                  else
                    VitalGauge(
                      value: _resultBpm ?? (health.latestReadings[VitalType.heartRate]?.value ?? 0),
                      minValue: 40,
                      maxValue: 180,
                      color: AppColors.heartRed,
                      label: 'Heart Rate',
                      unit: 'BPM',
                    ),
                  const SizedBox(height: 16),
                  if (_resultBpm != null)
                    StatusChip(value: _resultBpm!, type: VitalType.heartRate),
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: AppColors.heartRed, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            if (!_measuring)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: const InstructionRow(
                  steps: [
                    '1. Place your fingertip gently over the rear camera lens',
                    '2. Keep your hand still for 30 seconds',
                    '3. Ensure good lighting and slight pressure',
                  ],
                  icon: Icons.camera_rear_rounded,
                  color: AppColors.heartRed,
                ),
              ),

            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _measuring ? _stopMeasurement : _startMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _measuring ? AppColors.heartRed.withValues(alpha: 0.15) : AppColors.heartRed,
                  foregroundColor: _measuring ? AppColors.heartRed : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(
                  _measuring ? 'Stop Measuring' : 'Start Measurement',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // History Chart
            if (history.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('History', style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: TrendChart(readings: history, color: AppColors.heartRed, height: 140),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _LiveMeasurementView extends StatelessWidget {
  final double progress;

  const _LiveMeasurementView({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        HeartbeatWave(color: AppColors.heartRed, isActive: true),
        const SizedBox(height: 20),
        Text(
          'Measuring...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.heartRed),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toInt()}%  Keep your finger on the lens',
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final double value;
  final VitalType type;

  const StatusChip({required this.value, required this.type});

  @override
  Widget build(BuildContext context) {
    final r = VitalReading(id: '', type: type, value: value, timestamp: DateTime.now());
    final status = r.status;
    final color = status == HealthStatus.normal
        ? AppColors.breathGreen
        : status == HealthStatus.critical
            ? AppColors.danger
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class InstructionRow extends StatelessWidget {
  final List<String> steps;
  final IconData icon;
  final Color color;

  const InstructionRow({required this.steps, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text('How to measure', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 12),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        )),
      ],
    );
  }
}
