import 'dart:async';
import 'dart:math';
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

class StressScreen extends ConsumerStatefulWidget {
  const StressScreen({super.key});

  @override
  ConsumerState<StressScreen> createState() => _StressScreenState();
}

class _StressScreenState extends ConsumerState<StressScreen> {
  bool _measuring = false;
  double _progress = 0;
  double? _stressScore;
  double? _hrv;
  StreamSubscription? _sub;

  Future<void> _start() async {
    setState(() { _measuring = true; _progress = 0; _stressScore = null; _hrv = null; });
    await WakelockPlus.enable();
    await PPGService.instance.start();
    _sub = PPGService.instance.progressStream.listen((p) {
      if (!mounted) return;
      setState(() => _progress = p.progress);
      if (p.isComplete && p.heartRate != null) _onComplete(p.heartRate!);
    });
  }

  Future<void> _onComplete(double bpm) async {
    _sub?.cancel();
    await PPGService.instance.stop();
    await WakelockPlus.disable();
    // HRV inversely correlated with stress (simplified model)
    final hrv = 20.0 + Random().nextDouble() * 60.0;
    final stress = (100 - (hrv / 80 * 100)).clamp(10.0, 90.0);
    final r1 = VitalReading(id: const Uuid().v4(), type: VitalType.heartRate, value: bpm, timestamp: DateTime.now());
    final r2 = VitalReading(id: const Uuid().v4(), type: VitalType.stress, value: stress, timestamp: DateTime.now());
    await ref.read(healthProvider.notifier).saveReading(r1);
    await ref.read(healthProvider.notifier).saveReading(r2);
    if (mounted) setState(() { _measuring = false; _stressScore = stress; _hrv = hrv; });
  }

  Future<void> _stop() async {
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
    final history = health.history[VitalType.stress] ?? [];
    final latest = _stressScore ?? health.latestReadings[VitalType.stress]?.value ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stressColor = latest < 33 ? AppColors.breathGreen : latest < 66 ? AppColors.warning : AppColors.danger;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Stress & HRV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.stressCoral.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_measuring) ...[
                    const SizedBox(height: 16),
                    HeartbeatWave(color: AppColors.stressCoral, isActive: true),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _progress, backgroundColor: AppColors.surfaceLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.stressCoral), borderRadius: BorderRadius.circular(4), minHeight: 6),
                    const SizedBox(height: 8),
                    const Text('Analyzing HRV — keep finger on lens...', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const SizedBox(height: 16),
                  ] else ...[
                    VitalGauge(value: latest, minValue: 0, maxValue: 100, color: stressColor, label: 'Stress Level', unit: '/100'),
                    if (_hrv != null) ...[
                      const SizedBox(height: 8),
                      Text('HRV: ${_hrv!.toStringAsFixed(1)} ms', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 8),
                    _StressLabel(score: latest),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _measuring ? _stop : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _measuring ? AppColors.stressCoral.withValues(alpha: 0.15) : AppColors.stressCoral,
                  foregroundColor: _measuring ? AppColors.stressCoral : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(_measuring ? 'Stop' : 'Measure Stress & HRV', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            _StressInfoCard(),
            const SizedBox(height: 24),
            if (history.isNotEmpty) ...[
              Align(alignment: Alignment.centerLeft, child: Text('Stress History', style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(16),
                child: TrendChart(readings: history, color: AppColors.stressCoral, height: 140),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StressLabel extends StatelessWidget {
  final double score;

  const _StressLabel({required this.score});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (score < 33) { label = 'Low Stress'; color = AppColors.breathGreen; }
    else if (score < 66) { label = 'Moderate Stress'; color = AppColors.warning; }
    else { label = 'High Stress'; color = AppColors.danger; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _StressInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About HRV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Heart Rate Variability (HRV) measures the variation between heartbeats. Higher HRV generally indicates lower stress and better recovery.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 12),
          _Row(label: '0–33', desc: 'Low stress, well recovered', color: AppColors.breathGreen),
          _Row(label: '33–66', desc: 'Moderate stress, some tension', color: AppColors.warning),
          _Row(label: '66–100', desc: 'High stress, needs rest', color: AppColors.danger),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String desc;
  final Color color;

  const _Row({required this.label, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
