import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/vital_reading.dart';
import '../../providers/health_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trend_chart.dart';
import '../../widgets/vital_gauge.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  String _quality = 'Good';
  double? _savedHours;

  double get _sleepHours {
    int bedMins = _bedtime.hour * 60 + _bedtime.minute;
    int wakeMins = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeMins <= bedMins) wakeMins += 24 * 60;
    return (wakeMins - bedMins) / 60.0;
  }

  Future<void> _save() async {
    final hours = _sleepHours;
    final reading = VitalReading(
      id: const Uuid().v4(),
      type: VitalType.sleep,
      value: hours,
      timestamp: DateTime.now(),
      notes: 'Quality: $_quality',
    );
    await ref.read(healthProvider.notifier).saveReading(reading);
    setState(() => _savedHours = hours);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep logged!')),
      );
    }
  }

  Future<void> _pickTime(bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
    );
    if (picked != null) {
      setState(() {
        if (isBedtime) _bedtime = picked;
        else _wakeTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final history = health.history[VitalType.sleep] ?? [];
    final latest = health.latestReadings[VitalType.sleep];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Sleep'), floating: true),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Gauge
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.sleepPurple.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      VitalGauge(
                        value: _savedHours ?? latest?.value ?? 0,
                        minValue: 0,
                        maxValue: 12,
                        color: AppColors.sleepPurple,
                        label: 'Hours Slept',
                        unit: 'hrs',
                      ),
                      const SizedBox(height: 8),
                      _SleepQualityBadge(hours: _savedHours ?? latest?.value ?? 0),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Log sleep
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Log Last Night', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _TimeButton(label: 'Bedtime', time: _bedtime, color: AppColors.sleepPurple, onTap: () => _pickTime(true))),
                          const SizedBox(width: 12),
                          Expanded(child: _TimeButton(label: 'Wake Up', time: _wakeTime, color: AppColors.teal, onTap: () => _pickTime(false))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Duration: ${_sleepHours.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.sleepPurple)),
                      const SizedBox(height: 16),
                      const Text('Sleep Quality', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Poor', 'Fair', 'Good', 'Great'].map((q) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _quality = q),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _quality == q ? AppColors.sleepPurple : AppColors.sleepPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(q, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _quality == q ? Colors.white : AppColors.sleepPurple)),
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sleepPurple, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('Save Sleep Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sleep tips
                _SleepTipsCard(),
                const SizedBox(height: 24),

                if (history.isNotEmpty) ...[
                  Text('Sleep History', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.all(16),
                    child: TrendChart(readings: history, color: AppColors.sleepPurple, height: 140),
                  ),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;

  const _TimeButton({required this.label, required this.time, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(time.format(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SleepQualityBadge extends StatelessWidget {
  final double hours;

  const _SleepQualityBadge({required this.hours});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (hours == 0) { label = 'No data'; color = AppColors.textTertiary; }
    else if (hours >= 7 && hours <= 9) { label = 'Well Rested'; color = AppColors.breathGreen; }
    else if (hours < 7) { label = 'Too Little'; color = AppColors.warning; }
    else { label = 'Too Much'; color = AppColors.warning; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _SleepTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = ['Keep a consistent sleep schedule', 'Avoid screens 1 hour before bed', 'Keep your room cool and dark', 'Limit caffeine after 2pm'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_rounded, color: AppColors.sleepPurple, size: 18),
            const SizedBox(width: 8),
            const Text('Sleep Tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.sleepPurple)),
          ]),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.sleepPurple, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
