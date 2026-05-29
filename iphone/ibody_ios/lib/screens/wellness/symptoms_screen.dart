import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class SymptomEntry {
  final DateTime timestamp;
  final List<String> symptoms;
  final int severity;
  final String? notes;

  const SymptomEntry({
    required this.timestamp,
    required this.symptoms,
    required this.severity,
    this.notes,
  });
}

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final List<SymptomEntry> _entries = [];
  final Set<String> _selected = {};
  int _severity = 3;
  final _notesController = TextEditingController();

  static const _allSymptoms = [
    'Headache', 'Fatigue', 'Nausea', 'Dizziness',
    'Chest Pain', 'Shortness of Breath', 'Cough', 'Fever',
    'Sore Throat', 'Runny Nose', 'Body Aches', 'Chills',
    'Loss of Appetite', 'Stomach Pain', 'Joint Pain', 'Rash',
  ];

  void _save() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one symptom')),
      );
      return;
    }
    setState(() {
      _entries.insert(0, SymptomEntry(
        timestamp: DateTime.now(),
        symptoms: _selected.toList(),
        severity: _severity,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      ));
      _selected.clear();
      _severity = 3;
      _notesController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Symptoms logged!')),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Symptom Diary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Symptom selector
            Container(
              decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How are you feeling?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allSymptoms.map((s) {
                      final sel = _selected.contains(s);
                      return FilterChip(
                        label: Text(s),
                        selected: sel,
                        onSelected: (_) => setState(() { sel ? _selected.remove(s) : _selected.add(s); }),
                        selectedColor: AppColors.sleepPurple.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.sleepPurple,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? AppColors.sleepPurple : AppColors.textSecondary,
                        ),
                        side: BorderSide(color: sel ? AppColors.sleepPurple.withValues(alpha: 0.5) : AppColors.dividerLight),
                        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Severity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Mild', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      Expanded(
                        child: Slider(
                          value: _severity.toDouble(),
                          min: 1, max: 10, divisions: 9,
                          activeColor: AppColors.sleepPurple,
                          onChanged: (v) => setState(() => _severity = v.round()),
                        ),
                      ),
                      const Text('Severe', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      const SizedBox(width: 8),
                      Text('$_severity/10', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sleepPurple)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Additional notes (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sleepPurple, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.sleepPurple, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Log Symptoms', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // History
            if (_entries.isNotEmpty) ...[
              Text('Log History', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ..._entries.map((e) => _SymptomEntryCard(entry: e, isDark: isDark)),
            ] else
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Icon(Icons.edit_note_rounded, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    const Text('No symptoms logged yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SymptomEntryCard extends StatelessWidget {
  final SymptomEntry entry;
  final bool isDark;

  const _SymptomEntryCard({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final severityColor = entry.severity <= 3 ? AppColors.breathGreen : entry.severity <= 6 ? AppColors.warning : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(DateFormat('MMM d, h:mm a').format(entry.timestamp), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${entry.severity}/10', style: TextStyle(color: severityColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entry.symptoms.map((s) => Chip(
              label: Text(s),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sleepPurple),
              backgroundColor: AppColors.sleepPurple.withValues(alpha: 0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
          if (entry.notes != null) ...[
            const SizedBox(height: 8),
            Text(entry.notes!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
