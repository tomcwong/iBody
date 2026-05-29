import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'stress_screen.dart';
import 'skin_check_screen.dart';
import 'symptoms_screen.dart';

class WellnessTab extends StatelessWidget {
  const WellnessTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Wellness'), floating: true),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WellnessTile(
                  title: 'Stress & HRV',
                  description: 'Measure your stress level and heart rate variability',
                  icon: Icons.psychology_rounded,
                  color: AppColors.stressCoral,
                  tag: 'Camera required',
                  destination: const StressScreen(),
                ),
                const SizedBox(height: 12),
                _WellnessTile(
                  title: 'Skin Check',
                  description: 'AI-powered skin analysis using your camera',
                  icon: Icons.face_retouching_natural_rounded,
                  color: AppColors.skinPink,
                  tag: 'AI Powered',
                  destination: const SkinCheckScreen(),
                ),
                const SizedBox(height: 12),
                _WellnessTile(
                  title: 'Symptom Diary',
                  description: 'Log symptoms, medications, and how you feel',
                  icon: Icons.edit_note_rounded,
                  color: AppColors.sleepPurple,
                  tag: 'Daily tracking',
                  destination: const SymptomsScreen(),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String tag;
  final Widget destination;

  const _WellnessTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tag,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
