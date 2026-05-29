import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/vital_reading.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => ref.read(healthProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeAppBar(userName: user.name, isDark: isDark),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HealthScoreCard(score: health.healthScore, isDark: isDark),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Today\'s Vitals'),
                    const SizedBox(height: 12),
                    _VitalsGrid(health: health),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Activity & Sleep'),
                    const SizedBox(height: 12),
                    _ActivityRow(health: health),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Recent Readings'),
                    const SizedBox(height: 12),
                    _RecentReadingsList(readings: health.todaysReadings),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAppBar extends SliverPersistentHeaderDelegate {
  final String userName;
  final bool isDark;

  _HomeAppBar({required this.userName, required this.isDark});

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 160;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrink = shrinkOffset / maxExtent;
    return Container(
      color: isDark ? AppColors.bgDark : AppColors.bgLight,
      padding: EdgeInsets.fromLTRB(20, 50 * (1 - shrink) + 10, 20, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shrink < 0.5)
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: shrink < 0.5 ? 28 : 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.tealGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  bool shouldRebuild(_HomeAppBar old) => old.userName != userName;
}

class _HealthScoreCard extends StatelessWidget {
  final int score;
  final bool isDark;

  const _HealthScoreCard({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.teal : score >= 60 ? AppColors.tempOrange : AppColors.heartRed;
    final label = score >= 80 ? 'Excellent' : score >= 60 ? 'Good' : 'Needs Attention';

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Health Score',
                style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('/100', style: TextStyle(color: Colors.white38, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(Icons.favorite_rounded, color: color, size: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  final HealthState health;

  const _VitalsGrid({required this.health});

  @override
  Widget build(BuildContext context) {
    final vitals = [
      _VitalInfo(VitalType.heartRate, Icons.favorite_rounded, AppColors.heartRed, '—'),
      _VitalInfo(VitalType.spo2, Icons.water_drop_rounded, AppColors.oxygenBlue, '—'),
      _VitalInfo(VitalType.temperature, Icons.thermostat_rounded, AppColors.tempOrange, '—'),
      _VitalInfo(VitalType.respiratory, Icons.air_rounded, AppColors.breathGreen, '—'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: vitals.length,
      itemBuilder: (context, i) {
        final v = vitals[i];
        final reading = health.latestReadings[v.type];
        return MetricCard(
          title: v.type.displayName,
          value: reading?.formattedValue ?? '—',
          unit: reading != null ? v.type.unit : '',
          icon: v.icon,
          color: v.color,
          subtitle: reading != null
              ? DateFormat('h:mm a').format(reading.timestamp)
              : 'Not measured',
          isLoading: health.isLoading,
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final HealthState health;

  const _ActivityRow({required this.health});

  @override
  Widget build(BuildContext context) {
    final steps = health.latestReadings[VitalType.steps];
    final sleep = health.latestReadings[VitalType.sleep];

    return Row(
      children: [
        Expanded(
          child: MetricBannerCard(
            title: 'Steps Today',
            value: steps?.formattedValue ?? '0',
            unit: 'steps',
            icon: Icons.directions_walk_rounded,
            gradient: AppColors.tealGradient,
            badge: _stepsLabel(steps?.value ?? 0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricBannerCard(
            title: 'Last Sleep',
            value: sleep?.formattedValue ?? '—',
            unit: 'hrs',
            icon: Icons.bedtime_rounded,
            gradient: AppColors.sleepGradient,
            badge: _sleepLabel(sleep?.value ?? 0),
          ),
        ),
      ],
    );
  }

  String _stepsLabel(double steps) {
    if (steps >= 10000) return 'Goal Reached!';
    if (steps >= 7500) return 'Almost there';
    if (steps > 0) return 'Keep moving';
    return 'Start walking';
  }

  String _sleepLabel(double hrs) {
    if (hrs == 0) return 'No data';
    if (hrs >= 7 && hrs <= 9) return 'Well rested';
    if (hrs < 7) return 'Too little';
    return 'Too much';
  }
}

class _RecentReadingsList extends StatelessWidget {
  final List<VitalReading> readings;

  const _RecentReadingsList({required this.readings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (readings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.health_and_safety_outlined, size: 40, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text('No readings today', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              SizedBox(height: 4),
              Text('Tap Vitals to start measuring', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: readings.take(8).length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          indent: 64,
        ),
        itemBuilder: (context, i) {
          final r = readings[i];
          return _ReadingTile(reading: r);
        },
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final VitalReading reading;

  const _ReadingTile({required this.reading});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(reading.type);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconFor(reading.type), color: color, size: 20),
      ),
      title: Text(reading.type.displayName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(DateFormat('h:mm a').format(reading.timestamp),
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      trailing: RichText(
        text: TextSpan(
          text: reading.formattedValue,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
          children: [
            TextSpan(
              text: ' ${reading.type.unit}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(VitalType type) {
    switch (type) {
      case VitalType.heartRate: return AppColors.heartRed;
      case VitalType.spo2: return AppColors.oxygenBlue;
      case VitalType.temperature: return AppColors.tempOrange;
      case VitalType.respiratory: return AppColors.breathGreen;
      case VitalType.sleep: return AppColors.sleepPurple;
      case VitalType.stress: return AppColors.stressCoral;
      default: return AppColors.teal;
    }
  }

  IconData _iconFor(VitalType type) {
    switch (type) {
      case VitalType.heartRate: return Icons.favorite_rounded;
      case VitalType.spo2: return Icons.water_drop_rounded;
      case VitalType.temperature: return Icons.thermostat_rounded;
      case VitalType.respiratory: return Icons.air_rounded;
      case VitalType.sleep: return Icons.bedtime_rounded;
      case VitalType.stress: return Icons.psychology_rounded;
      default: return Icons.monitor_heart_rounded;
    }
  }
}

class _VitalInfo {
  final VitalType type;
  final IconData icon;
  final Color color;
  final String fallback;
  const _VitalInfo(this.type, this.icon, this.color, this.fallback);
}
