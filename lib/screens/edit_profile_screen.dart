import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  String? _avatarId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _avatarId = user?.avatarId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name khali rakha jabe na'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          fullName: _nameCtrl.text.trim(),
          avatarId: _avatarId,
          bio: _bioCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      final err = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Update failed'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 14),
                const Text('Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: UserAvatar(
                avatarId: _avatarId,
                fallbackInitial: (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : '?',
                size: 88,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choose Avatar',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: kAvatarPresets.map((preset) {
                final selected = preset.id == _avatarId;
                return GestureDetector(
                  onTap: () => setState(() => _avatarId = preset.id),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset.color.withValues(alpha: 0.18),
                      border: Border.all(color: selected ? preset.color : AppColors.cardBorder, width: selected ? 2.5 : 1.5),
                    ),
                    child: Icon(preset.icon, color: preset.color, size: 22),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            const Text('Full Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _input(_nameCtrl, 'Enter your full name'),
            const SizedBox(height: 18),
            const Text('Bio', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _input(_bioCtrl, 'Tell others about yourself', maxLines: 3),
            const SizedBox(height: 18),
            if (user != null) ...[
              const Text('UID', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(user.playerUid, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ),
            ],
            const SizedBox(height: 30),
            GradientButton(
              label: _saving ? 'Saving...' : 'Save Changes',
              height: 50,
              width: double.infinity,
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.purple),
        ),
      ),
    );
  }
}
