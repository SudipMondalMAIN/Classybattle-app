import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth/forgot_password_screen.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool openSecurity;
  final bool openSupport;
  final bool openAbout;
  const SettingsScreen({super.key, this.openSecurity = false, this.openSupport = false, this.openAbout = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openSecurity) _openSecurity();
      if (widget.openSupport) _openSupport();
      if (widget.openAbout) _openAbout();
    });
  }

  void _openSecurity() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  void _openSupport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Help & Support', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('support@classybattle.com',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'support@classybattle.com'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copied'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('Copy Email', style: TextStyle(color: AppColors.purple)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  void _openAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About ClassyBattle',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'ClassyBattle is a mobile eSports tournament platform where you can join BGMI, Free Fire and Valorant tournaments, win prizes, and track your ranking.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            const Text('App Version: 1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Tumi ki logout korte chao?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Na', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hae, Logout', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
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
                const Text('Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 20),
            _sectionLabel('Account'),
            _card([
              _tile(Icons.person_rounded, 'Edit Profile', subtitle: user?.fullName,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
              _tile(Icons.email_rounded, 'Email', subtitle: user?.email),
              _tile(Icons.phone_rounded, 'Phone Number', subtitle: user?.phoneNumber),
            ]),
            const SizedBox(height: 22),
            _sectionLabel('Notifications'),
            _card([
              _switchTile(Icons.notifications_active_rounded, 'Push Notifications', _pushEnabled,
                  (v) => setState(() => _pushEnabled = v)),
              _switchTile(Icons.mail_rounded, 'Email Notifications', _emailEnabled,
                  (v) => setState(() => _emailEnabled = v), isLast: true),
            ]),
            const SizedBox(height: 22),
            _sectionLabel('Security'),
            _card([
              _tile(Icons.lock_reset_rounded, 'Change Password', onTap: _openSecurity, isLast: true),
            ]),
            const SizedBox(height: 22),
            _sectionLabel('Support'),
            _card([
              _tile(Icons.help_outline_rounded, 'Help & Support', onTap: _openSupport),
              _tile(Icons.info_outline_rounded, 'About ClassyBattle', onTap: _openAbout, isLast: true),
            ]),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: _confirmLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: children),
      );

  Widget _tile(IconData icon, String label, {String? subtitle, VoidCallback? onTap, bool isLast = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 19),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 19),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(IconData icon, String label, bool value, ValueChanged<bool> onChanged, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 19),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.purple,
            inactiveTrackColor: AppColors.surfaceLight,
          ),
        ],
      ),
    );
  }
}
