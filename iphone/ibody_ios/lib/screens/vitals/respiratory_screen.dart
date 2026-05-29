import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/vital_reading.dart';
import '../../providers/health_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trend_chart.dart';
import '../../widgets/vital_gauge.dart';
import '../../widgets/vital_widgets.dart';

class RespiratoryScreen extends ConsumerStatefulWidget {
  const RespiratoryScreen({super.key});

  @override
  ConsumerState<RespiratoryScreen> createState() => _RespiratoryScreenState();
}

class _RespiratoryScreenState extends ConsumerState<RespiratoryScreen> with SingleTickerProviderStateMixin {
  bool _measuring = false;
  int _elapsed = 0;
  double? _result;
  Timer? _timer;
  late AnimationController _breathAnim;
  late Animation<double> _breathScale;

  static const _duration = 30;

  @override
  void initState() {
    super.initState();
    _breathAnim = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _breathScale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _breathAnim, curve: Curves.easeInOut));
  }

  void _start() {
    setState(() { _measuring = true; _elapsed = 0; _result = null; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _elapsed++);
      if (_elapsed >= _duration) { t.cancel(); _complete(); }
    });
  }

  Future<void> _complete() async {
    // Simulate respiratory rate measurement (12–20 br/min normal range)
    final rate = 12.0 + Random().nextDouble() * 8.0;
    final reading = VitalReading(id: const Uuid().v4(), type: VitalType.respiratory, value: rate, timestamp: DateTime.now());
    await ref.read(healthProvider.notifier).saveReading(reading);
    setState(() { _measuring = false; _result = rate; });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _measuring = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final history = health.history[VitalType.respiratory] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latestVal = _result ?? health.latestReadings[VitalType.respiratory]?.value ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Respiratory Rate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.breathGreen.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_measuring) ...[
                    AnimatedBuilder(
                      animation: _breathScale,
                      builder: (_, __) => Transform.scale(
                        scale: _breathScale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.breathGreen.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.breathGreen.withValues(alpha: 0.4), width: 2),
                          ),
                          child: const Icon(Icons.air_rounded, size: 56, color: AppColors.breathGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _breathAnim.value > 0.5 ? 'Breathe out...' : 'Breathe in...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.breathGreen),
                    ),
                    const SizedBox(height: 8),
                    Text('${_duration - _elapsed}s remaining', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _elapsed / _duration, backgroundColor: AppColors.surfaceLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.breathGreen), borderRadius: BorderRadius.circular(4), minHeight: 6),
                    const SizedBox(height: 8),
                  ] else ...[
                    VitalGauge(value: latestVal, minValue: 0, maxValue: 40, color: AppColors.breathGreen, label: 'Respiratory Rate', unit: 'br/min'),
                    const SizedBox(height: 12),
                    if (_result != null) StatusChip(value: _result!, type: VitalType.respiratory),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_measuring)
              Container(
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(16),
                child: const InstructionRow(
                  steps: [
                    '1. Sit or lie down comfortably',
                    '2. Breathe naturally — do not force it',
                    '3. Follow the breathing animation for 30 seconds',
                  ],
                  icon: Icons.air_rounded,
                  color: AppColors.breathGreen,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _measuring ? _stop : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _measuring ? AppColors.breathGreen.withValues(alpha: 0.15) : AppColors.breathGreen,
                  foregroundColor: _measuring ? AppColors.breathGreen : Colors.white,
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
                child: TrendChart(readings: history, color: AppColors.breathGreen, height: 140),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
