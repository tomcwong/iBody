import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/vital_reading.dart';
import '../../providers/health_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trend_chart.dart';
import '../../widgets/vital_gauge.dart';
import '../../widgets/vital_widgets.dart';

class TemperatureScreen extends ConsumerStatefulWidget {
  const TemperatureScreen({super.key});

  @override
  ConsumerState<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends ConsumerState<TemperatureScreen> {
  final _controller = TextEditingController();
  bool _scanning = false;
  double? _result;
  int _methodIndex = 0; // 0 = Manual, 1 = Bluetooth

  Future<void> _saveManual() async {
    final val = double.tryParse(_controller.text);
    if (val == null || val < 90 || val > 110) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid temperature (90°F – 110°F)')),
      );
      return;
    }
    final reading = VitalReading(
      id: const Uuid().v4(),
      type: VitalType.temperature,
      value: val,
      timestamp: DateTime.now(),
    );
    await ref.read(healthProvider.notifier).saveReading(reading);
    setState(() => _result = val);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final history = health.history[VitalType.temperature] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latestVal = _result ?? health.latestReadings[VitalType.temperature]?.value ?? 98.6;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Body Temperature')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current reading
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.tempOrange.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  VitalGauge(value: latestVal, minValue: 95, maxValue: 106, color: AppColors.tempOrange, label: 'Temperature', unit: '°F'),
                  const SizedBox(height: 12),
                  if (_result != null) StatusChip(value: _result!, type: VitalType.temperature),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Method toggle
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _MethodButton(label: 'Manual Entry', selected: _methodIndex == 0, onTap: () => setState(() => _methodIndex = 0))),
                  Expanded(child: _MethodButton(label: 'Bluetooth Device', selected: _methodIndex == 1, onTap: () => setState(() => _methodIndex = 1))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_methodIndex == 0) ...[
              // Manual entry
              Container(
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter Reading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Temperature (°F)',
                        hintText: 'e.g. 98.6',
                        suffixText: '°F',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.tempOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveManual,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tempOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Save Reading', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Bluetooth scan
              _BluetoothPanel(scanning: _scanning, onScan: () => setState(() => _scanning = !_scanning)),
            ],

            // Normal ranges
            const SizedBox(height: 16),
            _TempRangeTable(),

            const SizedBox(height: 24),
            if (history.isNotEmpty) ...[
              Align(alignment: Alignment.centerLeft, child: Text('History', style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(16),
                child: TrendChart(readings: history, color: AppColors.tempOrange, height: 140),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.tempOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BluetoothPanel extends StatelessWidget {
  final bool scanning;
  final VoidCallback onScan;

  const _BluetoothPanel({required this.scanning, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.bluetooth_rounded, size: 40, color: AppColors.tempOrange),
          const SizedBox(height: 12),
          const Text('Connect a Bluetooth thermometer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Compatible with Kinsa, Withings, and other BLE health devices.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: scanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search_rounded, size: 18),
            label: Text(scanning ? 'Scanning...' : 'Scan for Devices'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tempOrange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ],
      ),
    );
  }
}

class _TempRangeTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Below 97°F', 'Low (Hypothermia risk)', AppColors.oxygenBlue),
      ('97°F – 99°F', 'Normal', AppColors.breathGreen),
      ('99°F – 100.4°F', 'Low-grade fever', AppColors.warning),
      ('Above 100.4°F', 'Fever — seek care', AppColors.danger),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Temperature Ranges', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(r.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(r.$2, style: TextStyle(fontSize: 12, color: r.$3, fontWeight: FontWeight.w500)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
