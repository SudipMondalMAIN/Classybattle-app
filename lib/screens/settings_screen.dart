import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notification_preferences_model.dart';
import '../providers/home_providers.dart';
import '../providers/profile_providers.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/profile/account_section.dart';
import '../content/legal_content.dart';
import 'edit_profile_screen.dart';
import 'faq_screen.dart';
import 'legal_info_screen.dart';
import 'support_chat_screen.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  void _notAvailable(String what) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$what — not available yet')));
  }

  Future<void> _openReportForm() async {
    final uri = Uri.parse('https://forms.gle/LdntkNogVcGAuC3F7');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _notAvailable('Report form');
    }
  }

  Future<void> _showInfo(String title, String body) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14101F),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          body,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.purpleSoft),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14101F),
        title: const Text(
          'Log out?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You will need to log in again to access your account.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.live),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await settingsService.logout();
    ref.invalidate(currentUserProvider);
    ref.invalidate(walletProvider);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _startChangePassword(String email) async {
    try {
      await settingsService.requestPasswordResetOtp(email);
    } catch (_) {
      // still proceed to the OTP sheet -- forgot-password is designed
      // to always return a generic success message either way.
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientTop,
              AppColors.backgroundGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    const _SectionLabel('Account'),
                    userAsync.when(
                      data: (user) => AccountSectionCard(
                        rows: [
                          AccountRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Edit Profile',
                            onTap: user == null
                                ? () => _notAvailable('Edit Profile')
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfileScreen(user: user),
                                    ),
                                  ),
                          ),
                          AccountRow(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                            onTap: user == null
                                ? () => _notAvailable('Change Password')
                                : () => _startChangePassword(user.email),
                          ),
                          AccountRow(
                            icon: Icons.shield_outlined,
                            label: 'Security',
                            onTap: () => _showInfo(
                              'Security',
                              'Your login activity and account risk score are '
                                  'tracked automatically for your protection.',
                            ),
                          ),
                          AccountRow(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Privacy',
                            onTap: () => _showInfo(
                              'Privacy',
                              'Your data is used only to run tournaments, '
                                  'payouts, and your ClassyBattle account.',
                            ),
                          ),
                        ],
                      ),
                      loading: () => const _CardSkeleton(),
                      error: (_, __) => const _CardSkeleton(),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Notifications'),
                    prefsAsync.when(
                      data: (prefs) => _NotificationsCard(
                        key: ValueKey(
                          prefs?.pushEnabled.toString() ?? 'logged-out',
                        ),
                        initialPrefs: prefs,
                        onUnauthenticated: () =>
                            _notAvailable('Notification settings'),
                      ),
                      loading: () => const _CardSkeleton(),
                      error: (_, __) => const _CardSkeleton(),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Application'),
                    AccountSectionCard(
                      rows: [
                        AccountRow(
                          icon: Icons.info_outline_rounded,
                          label: 'App Version',
                          trailingText: _appVersion.isEmpty ? '—' : _appVersion,
                          trailing: const SizedBox.shrink(),
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Support'),
                    AccountSectionCard(
                      rows: [
                        AccountRow(
                          icon: Icons.headset_mic_outlined,
                          label: 'Help & Support',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SupportChatScreen(),
                            ),
                          ),
                        ),
                        AccountRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Contact Support',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SupportChatScreen(),
                            ),
                          ),
                        ),
                        AccountRow(
                          icon: Icons.help_outline_rounded,
                          label: 'FAQ',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FaqScreen(),
                            ),
                          ),
                        ),
                        AccountRow(
                          icon: Icons.flag_outlined,
                          label: 'Report a Problem',
                          onTap: () => _openReportForm(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('About'),
                    AccountSectionCard(
                      rows: [
                        AccountRow(
                          icon: Icons.article_outlined,
                          label: 'About ClassyBattle',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LegalInfoScreen(
                                title: 'About ClassyBattle',
                                sections: aboutSections,
                              ),
                            ),
                          ),
                        ),
                        AccountRow(
                          icon: Icons.description_outlined,
                          label: 'Terms & Conditions',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LegalInfoScreen(
                                title: 'Terms & Conditions',
                                sections: termsSections,
                                lastUpdated: 'August 2026',
                              ),
                            ),
                          ),
                        ),
                        AccountRow(
                          icon: Icons.policy_outlined,
                          label: 'Privacy Policy',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LegalInfoScreen(
                                title: 'Privacy Policy',
                                sections: privacySections,
                                lastUpdated: 'August 2026',
                              ),
                            ),
                          ),
                        ),
                        AccountRow(
                          icon: Icons.currency_exchange_rounded,
                          label: 'Refund Policy',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LegalInfoScreen(
                                title: 'Refund Policy',
                                sections: refundSections,
                                lastUpdated: 'August 2026',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Account Actions'),
                    AccountSectionCard(
                      rows: [
                        AccountRow(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.live,
                          label: 'Logout',
                          trailing: const SizedBox.shrink(),
                          onTap: _confirmLogout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      child: const SizedBox(
        height: 20,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.purple,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsCard extends StatefulWidget {
  const _NotificationsCard({
    super.key,
    required this.initialPrefs,
    required this.onUnauthenticated,
  });

  final NotificationPreferencesModel? initialPrefs;
  final VoidCallback onUnauthenticated;

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  bool _saving = false;
  NotificationPreferencesModel? _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = widget.initialPrefs;
  }

  Future<void> _toggle({bool? push, bool? inApp, bool? email}) async {
    final prefs = _prefs;
    if (prefs == null) {
      widget.onUnauthenticated();
      return;
    }
    final previous = prefs;
    setState(() {
      _prefs = prefs.copyWith(
        pushEnabled: push,
        inAppEnabled: inApp,
        emailEnabled: email,
      );
      _saving = true;
    });
    try {
      final updated = await settingsService.updateNotificationPreferences(
        pushEnabled: push,
        inAppEnabled: inApp,
        emailEnabled: email,
      );
      if (mounted) setState(() => _prefs = updated);
    } on UnauthenticatedException {
      widget.onUnauthenticated();
      if (mounted) setState(() => _prefs = previous);
    } catch (_) {
      if (mounted) setState(() => _prefs = previous);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    return GlassContainer(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.notifications_active_outlined,
            label: 'Push Notifications',
            value: prefs?.pushEnabled ?? false,
            enabled: !_saving,
            onChanged: (v) => _toggle(push: v),
          ),
          const Divider(
            height: 1,
            color: AppColors.glassBorder,
            indent: 16,
            endIndent: 16,
          ),
          _ToggleRow(
            icon: Icons.apps_rounded,
            label: 'In-App Notifications',
            value: prefs?.inAppEnabled ?? false,
            enabled: !_saving,
            onChanged: (v) => _toggle(inApp: v),
          ),
          const Divider(
            height: 1,
            color: AppColors.glassBorder,
            indent: 16,
            endIndent: 16,
          ),
          _ToggleRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email Notifications',
            value: prefs?.emailEnabled ?? false,
            enabled: !_saving,
            onChanged: (v) => _toggle(email: v),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.purple,
            inactiveTrackColor: AppColors.glassFillStrong,
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.email});
  final String email;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _otpVerified = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter the code sent to your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await settingsService.verifyPasswordResetOtp(
        widget.email,
        _otpCtrl.text.trim(),
      );
      setState(() => _otpVerified = true);
    } on SettingsActionException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not verify that code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await settingsService.resetPassword(
        email: widget.email,
        otp: _otpCtrl.text.trim(),
        newPassword: _passwordCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed. Please log in again.'),
          ),
        );
      }
    } on SettingsActionException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reset your password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF14101F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _otpVerified ? 'Set New Password' : 'Change Password',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _otpVerified
                  ? 'Enter your new password.'
                  : 'We sent a verification code to ${widget.email}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            if (!_otpVerified)
              _SheetField(controller: _otpCtrl, hint: 'Verification code')
            else
              _SheetField(
                controller: _passwordCtrl,
                hint: 'New password',
                obscure: true,
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.live, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.purpleButton,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : (_otpVerified ? _resetPassword : _verifyOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _otpVerified ? 'Reset Password' : 'Verify Code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
