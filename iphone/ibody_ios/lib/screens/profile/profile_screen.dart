import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  String _gender = 'Other';
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(userProvider);
    _nameCtrl = TextEditingController(text: p.name);
    _ageCtrl = TextEditingController(text: p.age.toString());
    _heightCtrl = TextEditingController(text: p.heightCm.toStringAsFixed(0));
    _weightCtrl = TextEditingController(text: p.weightKg.toStringAsFixed(1));
    _gender = p.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = UserProfile(
      name: _nameCtrl.text.isEmpty ? 'User' : _nameCtrl.text,
      age: int.tryParse(_ageCtrl.text) ?? 30,
      heightCm: double.tryParse(_heightCtrl.text) ?? 170.0,
      weightKg: double.tryParse(_weightCtrl.text) ?? 70.0,
      gender: _gender,
    );
    await ref.read(userProvider.notifier).update(profile);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Profile'),
            floating: true,
            actions: [
              TextButton(
                onPressed: () => setState(() { if (_editing) _save(); else _editing = true; }),
                child: Text(_editing ? 'Save' : 'Edit', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Avatar + Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: AppColors.navyGradient,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: Center(
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_editing)
                        Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // BMI Card
                if (!_editing)
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.navyGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'BMI', value: profile.bmi.toStringAsFixed(1), sub: profile.bmiCategory),
                        _Divider(),
                        _StatItem(label: 'Height', value: '${profile.heightCm.toInt()}', sub: 'cm'),
                        _Divider(),
                        _StatItem(label: 'Weight', value: '${profile.weightKg.toStringAsFixed(0)}', sub: 'kg'),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Edit form or info display
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _editing ? _EditForm(
                    nameCtrl: _nameCtrl,
                    ageCtrl: _ageCtrl,
                    heightCtrl: _heightCtrl,
                    weightCtrl: _weightCtrl,
                    gender: _gender,
                    onGenderChanged: (g) => setState(() => _gender = g),
                  ) : _ProfileInfoList(profile: profile),
                ),

                const SizedBox(height: 20),

                // Settings section
                _SettingsSection(),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _StatItem({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: Colors.white12);
}

class _ProfileInfoList extends StatelessWidget {
  final UserProfile profile;

  const _ProfileInfoList({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Age', '${profile.age} years'),
      ('Gender', profile.gender),
      ('Height', '${profile.heightCm.toInt()} cm (${profile.heightFt.toStringAsFixed(1)} ft)'),
      ('Weight', '${profile.weightKg.toStringAsFixed(1)} kg (${profile.weightLbs.toStringAsFixed(0)} lbs)'),
    ];
    return Column(
      children: rows.asMap().entries.map((e) {
        final last = e.key == rows.length - 1;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(e.value.$1, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(e.value.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (!last) const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }
}

class _EditForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final String gender;
  final ValueChanged<String> onGenderChanged;

  const _EditForm({
    required this.nameCtrl,
    required this.ageCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.gender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(controller: nameCtrl, label: 'Name'),
        const SizedBox(height: 12),
        _Field(controller: ageCtrl, label: 'Age', keyboard: TextInputType.number),
        const SizedBox(height: 12),
        _Field(controller: heightCtrl, label: 'Height (cm)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        _Field(controller: weightCtrl, label: 'Weight (kg)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(gender),
          initialValue: gender,
          decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) { if (v != null) onGenderChanged(v); },
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;

  const _Field({required this.controller, required this.label, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (Icons.notifications_rounded, 'Notifications', AppColors.teal),
      (Icons.lock_rounded, 'Privacy & Data', AppColors.oxygenBlue),
      (Icons.health_and_safety_rounded, 'Apple Health Sync', AppColors.breathGreen),
      (Icons.help_outline_rounded, 'Help & Support', AppColors.sleepPurple),
    ];
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: items.asMap().entries.map((e) {
          final last = e.key == items.length - 1;
          final item = e.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: item.$3.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(item.$1, color: item.$3, size: 18),
                ),
                title: Text(item.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
                onTap: () {},
              ),
              if (!last) Divider(height: 1, indent: 68, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
            ],
          );
        }).toList(),
      ),
    );
  }
}
