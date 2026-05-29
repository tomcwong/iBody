import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'heart_rate_screen.dart';
import 'spo2_screen.dart';
import 'temperature_screen.dart';
import 'respiratory_screen.dart';

class VitalsTab extends StatelessWidget {
  const VitalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Vitals'),
            floating: true,
            pinned: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _VitalTile(
                  title: 'Heart Rate',
                  subtitle: 'Measure via camera',
                  icon: Icons.favorite_rounded,
                  color: AppColors.heartRed,
                  gradient: AppColors.heartGradient,
                  destination: const HeartRateScreen(),
                ),
                _VitalTile(
                  title: 'Blood Oxygen',
                  subtitle: 'SpO2 level',
                  icon: Icons.water_drop_rounded,
                  color: AppColors.oxygenBlue,
                  gradient: AppColors.oxygenGradient,
                  destination: const SpO2Screen(),
                ),
                _VitalTile(
                  title: 'Temperature',
                  subtitle: 'Connect thermometer',
                  icon: Icons.thermostat_rounded,
                  color: AppColors.tempOrange,
                  gradient: AppColors.tempGradient,
                  destination: const TemperatureScreen(),
                ),
                _VitalTile(
                  title: 'Respiratory',
                  subtitle: 'Breathing rate',
                  icon: Icons.air_rounded,
                  color: AppColors.breathGreen,
                  gradient: LinearGradient(
                    colors: [AppColors.breathGreen.withValues(alpha: 0.8), AppColors.breathGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  destination: const RespiratoryScreen(),
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final Widget destination;

  const _VitalTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Measure',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
