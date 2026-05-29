import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';

class SkinCheckScreen extends StatefulWidget {
  const SkinCheckScreen({super.key});

  @override
  State<SkinCheckScreen> createState() => _SkinCheckScreenState();
}

class _SkinCheckScreenState extends State<SkinCheckScreen> {
  File? _image;
  bool _analyzing = false;
  Map<String, dynamic>? _result;
  final _picker = ImagePicker();

  Future<void> _captureImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _analyzing = true; _result = null; });
    await Future.delayed(const Duration(seconds: 2)); // Simulated AI analysis
    setState(() {
      _analyzing = false;
      _result = _simulatedAnalysis();
    });
  }

  Map<String, dynamic> _simulatedAnalysis() {
    return {
      'overall': 'Healthy',
      'score': 82,
      'findings': [
        {'label': 'Hydration', 'value': 'Good', 'color': 0xFF2ED573},
        {'label': 'Texture', 'value': 'Smooth', 'color': 0xFF2ED573},
        {'label': 'Tone', 'value': 'Even', 'color': 0xFF2ED573},
        {'label': 'Concerns', 'value': 'Minor dryness', 'color': 0xFFFFC107},
      ],
      'tip': 'Maintain daily SPF protection and hydration. Consider a gentle exfoliant once a week.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Skin Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Disclaimer
            Container(
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(14),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For wellness awareness only. Not a medical diagnosis. Consult a dermatologist for skin concerns.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Image area
            GestureDetector(
              onTap: () => _showSourceSheet(),
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.skinPink.withValues(alpha: 0.3), width: 2),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 48, color: AppColors.skinPink.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text('Tap to capture or upload skin photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _captureImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.skinPink, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _captureImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, foregroundColor: AppColors.skinPink, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Analysis result
            if (_analyzing)
              Container(
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(24),
                child: const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.skinPink, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text('Analyzing skin...', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else if (_result != null)
              _AnalysisResultCard(result: _result!),

            const SizedBox(height: 20),

            // Tips
            Container(
              decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Best Practices for Scanning', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...['Use natural lighting (no harsh flash)', 'Hold phone 8–12 inches from skin', 'Clean the area and remove makeup', 'Capture a flat, well-lit region'].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.skinPink, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                    ]),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.camera_alt_rounded, color: AppColors.skinPink), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); _captureImage(ImageSource.camera); }),
              ListTile(leading: const Icon(Icons.photo_library_rounded, color: AppColors.skinPink), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); _captureImage(ImageSource.gallery); }),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _AnalysisResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final findings = result['findings'] as List;
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Analysis Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.breathGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(result['overall'] as String, style: const TextStyle(color: AppColors.breathGreen, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: findings.map((f) {
              final color = Color(f['color'] as int);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Column(
                  children: [
                    Text(f['label'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(f['value'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              );
            }).toList(),
          ),
          if (result['tip'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.skinPink.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded, color: AppColors.skinPink, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['tip'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
