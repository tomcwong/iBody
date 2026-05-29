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
import '../../widgets/vital_widgets.dart';

class SpO2Screen extends ConsumerStatefulWidget {
  const SpO2Screen({super.key});

  @override
  ConsumerState<SpO2Screen> createState() => _SpO2ScreenState();
}

class _SpO2ScreenState extends ConsumerState<SpO2Screen> {
  bool _measuring = false;
  double _progress = 0;
  double? _resultSpO2;
  StreamSubscription? _sub;

  Future<void> _start() async {
    setState(() { _measuring = true; _progress = 0; _resultSpO2 = null; });
    await WakelockPlus.enable();
    await PPGService.instance.start();

    _sub = PPGService.instance.progressStream.listen((p) {
      if (!mounted) return;
      setState(() => _progress = p.progress);
      if (p.isComplete && p.spo2 != null) _onComplete(p.spo2!);
    });
  }

  Future<void> _onComplete(double spo2) async {
    _sub?.cancel();
    await PPGService.instance.stop();
    await WakelockPlus.disable();

    final reading = VitalReading(
      id: const Uuid().v4(),
      type: VitalType.spo2,
      value: spo2,
      timestamp: DateTime.now(),
    );
    await ref.read(healthProvider.notifier).saveReading(reading);
    if (mounted) setState(() { _measuring = false; _resultSpO2 = spo2; });
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
    final history = health.history[VitalType.spo2] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latestVal = _resultSpO2 ?? health.latestReadings[VitalType.spo2]?.value ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Blood Oxygen (SpO2)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.oxygenBlue.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_measuring) ...[
                    const SizedBox(height: 20),
                    HeartbeatWave(color: AppColors.oxygenBlue, isActive: true),
                    const SizedBox(height: 16),
                    Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.oxygenBlue)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _progress, backgroundColor: AppColors.surfaceLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.oxygenBlue), borderRadius: BorderRadius.circular(4), minHeight: 6),
                    const SizedBox(height: 8),
                    const Text('Keep finger on lens...', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const SizedBox(height: 20),
                  ] else ...[
                    VitalGauge(value: latestVal, minValue: 80, maxValue: 100, color: AppColors.oxygenBlue, label: 'Blood Oxygen', unit: '%'),
                    const SizedBox(height: 12),
                    if (_resultSpO2 != null) StatusChip(value: _resultSpO2!, type: VitalType.spo2),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Normal range info
            _NormalRangeCard(),

            const SizedBox(height: 16),
            if (!_measuring)
              Container(
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(16),
                child: const InstructionRow(
                  steps: [
                    '1. Place fingertip firmly over the rear camera lens',
                    '2. Turn on the flashlight — keep covered fully',
                    '3. Remain still for 30 seconds',
                  ],
                  icon: Icons.water_drop_rounded,
                  color: AppColors.oxygenBlue,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _measuring ? _stop : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _measuring ? AppColors.oxygenBlue.withValues(alpha: 0.15) : AppColors.oxygenBlue,
                  foregroundColor: _measuring ? AppColors.oxygenBlue : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(_measuring ? 'Stop' : 'Start Measurement', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            if (history.isNotEmpty) ...[
              Align(alignment: Alignment.centerLeft, child: Text('History', style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(16),
                child: TrendChart(readings: history, color: AppColors.oxygenBlue, height: 140),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _NormalRangeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: AppColors.oxygenBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.oxygenBlue.withValues(alpha: 0.2))),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.oxygenBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Normal Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.oxygenBlue)),
                const SizedBox(height: 2),
                Text('95-100% is normal. Below 90% requires medical attention.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
