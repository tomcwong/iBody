import 'package:flutter/material.dart';
import '../models/vital_reading.dart';
import '../theme/app_colors.dart';

/// Colored status badge (Normal / Low / High / Critical).
class StatusChip extends StatelessWidget {
  final double value;
  final VitalType type;

  const StatusChip({super.key, required this.value, required this.type});

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
      child: Text(status.label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

/// Numbered instruction list shown on measurement screens.
class InstructionRow extends StatelessWidget {
  final List<String> steps;
  final IconData icon;
  final Color color;

  const InstructionRow({
    super.key,
    required this.steps,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text('How to measure',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 12),
        ...steps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(s,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            )),
      ],
    );
  }
}
