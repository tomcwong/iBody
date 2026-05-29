import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated circular arc gauge for displaying vital sign measurements.
class VitalGauge extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final Color color;
  final String label;
  final String unit;
  final double size;

  const VitalGauge({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.label,
    required this.unit,
    this.size = 220,
  });

  @override
  State<VitalGauge> createState() => _VitalGaugeState();
}

class _VitalGaugeState extends State<VitalGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(VitalGauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _animation = Tween<double>(begin: old.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _GaugePainter(
              value: _animation.value,
              min: widget.minValue,
              max: widget.maxValue,
              color: widget.color,
              isDark: isDark,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _animation.value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.unit,
                    style: TextStyle(
                      fontSize: widget.size * 0.065,
                      fontWeight: FontWeight.w500,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.size * 0.055,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  final bool isDark;

  const _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    // Track background
    final trackPaint = Paint()
      ..color = isDark ? AppColors.surfaceDark : AppColors.surfaceLight
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress arc
    final progress = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle * progress,
        colors: [color.withValues(alpha: 0.7), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );

    // Tip dot
    if (progress > 0.01) {
      final tipAngle = startAngle + sweepAngle * progress;
      final tipX = center.dx + radius * cos(tipAngle);
      final tipY = center.dy + radius * sin(tipAngle);
      canvas.drawCircle(
        Offset(tipX, tipY),
        8,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(tipX, tipY),
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

/// Pulsing waveform animation shown during live PPG measurement
class HeartbeatWave extends StatefulWidget {
  final Color color;
  final bool isActive;

  const HeartbeatWave({super.key, required this.color, required this.isActive});

  @override
  State<HeartbeatWave> createState() => _HeartbeatWaveState();
}

class _HeartbeatWaveState extends State<HeartbeatWave> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _WavePainter(
          progress: _ctrl.value,
          color: widget.color,
          isActive: widget.isActive,
        ),
        size: const Size(double.infinity, 80),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isActive;

  const _WavePainter({required this.progress, required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? color : color.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final h = size.height;
    final w = size.width;
    final offset = progress * w;

    path.moveTo(0, h / 2);

    for (double x = 0; x < w; x++) {
      final xVal = (x - offset) % w;
      double y = h / 2;
      // ECG-like waveform
      final segment = (xVal / w * 4) % 1.0;
      if (segment < 0.1) y = h / 2 - 5 * sin(segment / 0.1 * pi);
      else if (segment < 0.15) y = h / 2 + 30 * sin((segment - 0.1) / 0.05 * pi);
      else if (segment < 0.2) y = h / 2 - 20 * sin((segment - 0.15) / 0.05 * pi);
      else if (segment < 0.3) y = h / 2 + 5 * sin((segment - 0.2) / 0.1 * pi);

      if (x == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress || old.isActive != isActive;
}
