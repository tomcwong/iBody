import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/vital_reading.dart';
import '../../providers/health_provider.dart';
import '../../services/health_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/trend_chart.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _syncing = false;

  Future<void> _syncHealthKit() async {
    setState(() => _syncing = true);
    final steps = await HealthService.instance.getTodaySteps();
    if (steps > 0) {
      await ref.read(healthProvider.notifier).saveReading(
        VitalReading(id: const Uuid().v4(), type: VitalType.steps, value: steps.toDouble(), timestamp: DateTime.now()),
      );
    }
    setState(() => _syncing = false);
  }

  @override
  void initState() {
    super.initState();
    _syncHealthKit();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final stepsHistory = health.history[VitalType.steps] ?? [];
    final latestSteps = health.latestReadings[VitalType.steps];
    final steps = latestSteps?.value.toInt() ?? 0;
    final goal = 10000;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Activity'),
            floating: true,
            actions: [
              IconButton(
                icon: _syncing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
                    : const Icon(Icons.sync_rounded),
                onPressed: _syncHealthKit,
                tooltip: 'Sync with Health',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Steps Banner
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.tealGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Today\'s Steps', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          const Icon(Icons.directions_walk_rounded, color: Colors.white60, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            NumberFormat('#,###').format(steps),
                            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: -1.5, height: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 6),
                            child: Text('/ $goal', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        progress >= 1 ? 'Goal reached! Great job!' : '${NumberFormat('#,###').format(goal - steps)} steps to go',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Calories',
                        value: (steps * 0.04).toStringAsFixed(0),
                        unit: 'kcal',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.heartRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Distance',
                        value: (steps * 0.000762).toStringAsFixed(2),
                        unit: 'km',
                        icon: Icons.map_rounded,
                        color: AppColors.oxygenBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Active Min',
                        value: (steps / 100).toStringAsFixed(0),
                        unit: 'min',
                        icon: Icons.timer_rounded,
                        color: AppColors.tempOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Move Goal',
                        value: '${(progress * 100).toInt()}',
                        unit: '%',
                        icon: Icons.flag_rounded,
                        color: AppColors.breathGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Weekly Chart
                if (stepsHistory.isNotEmpty) ...[
                  Text('Steps History', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TrendChart(readings: stepsHistory, color: AppColors.teal, height: 160, showDots: true),
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
