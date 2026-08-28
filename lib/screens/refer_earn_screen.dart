import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/referral_model.dart';
import '../providers/referral_providers.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/referral_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';

class ReferEarnScreen extends ConsumerStatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  ConsumerState<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends ConsumerState<ReferEarnScreen> {
  final _applyCtrl = TextEditingController();
  bool _applying = false;
  String? _applyError;
  String? _applySuccess;

  @override
  void dispose() {
    _applyCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }

  Future<void> _shareCode(String code) async {
    final message = Uri.encodeComponent(
      'Join me on ClassyBattle! Use my referral code $code when you sign up '
      'and we both earn rewards. 🎮',
    );
    final uri = Uri.parse('whatsapp://send?text=$message');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fall back to copying so the user still has something to paste
      // into whichever app they actually want to share through.
      await _copyCode(code);
    }
  }

  Future<void> _applyCode() async {
    final code = _applyCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _applyError = 'Enter a referral code.');
      return;
    }
    setState(() {
      _applying = true;
      _applyError = null;
      _applySuccess = null;
    });
    try {
      await referralService.applyCode(code);
      setState(() => _applySuccess = 'Referral code applied!');
      _applyCtrl.clear();
      ref.invalidate(myReferralCodeProvider);
      ref.invalidate(referralHistoryProvider);
    } on ReferralActionException catch (e) {
      setState(() => _applyError = e.message);
    } on UnauthenticatedException {
      setState(() => _applyError = 'Please log in to apply a referral code.');
    } catch (_) {
      setState(() => _applyError = 'Could not apply that referral code.');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeAsync = ref.watch(myReferralCodeProvider);
    final historyAsync = ref.watch(referralHistoryProvider);

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
                      'Refer & Earn',
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myReferralCodeProvider);
                    ref.invalidate(referralHistoryProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      codeAsync.when(
                        data: (data) => _CodeCard(
                          data: data,
                          onCopy: () => _copyCode(data.referralCode),
                          onShare: () => _shareCode(data.referralCode),
                        ),
                        loading: () => const _CardSkeleton(height: 220),
                        error: (e, __) => _ErrorNotice(
                          message: e is UnauthenticatedException
                              ? 'Log in to see your referral code.'
                              : 'Could not load your referral code.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('Have a code?'),
                      GlassContainer(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _applyCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: 'Enter referral code',
                                      hintStyle: TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 40,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.purpleButton,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _applying ? null : _applyCode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _applying
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Apply',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_applyError != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _applyError!,
                                style: const TextStyle(
                                  color: AppColors.live,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (_applySuccess != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _applySuccess!,
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('Your Referrals'),
                      historyAsync.when(
                        data: (items) => items.isEmpty
                            ? const _EmptyHistory()
                            : Column(
                                children: [
                                  for (final item in items) ...[
                                    _ReferralHistoryTile(item: item),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                        loading: () => const _CardSkeleton(height: 100),
                        error: (e, __) => _ErrorNotice(
                          message: e is UnauthenticatedException
                              ? 'Log in to see your referrals.'
                              : 'Could not load your referral history.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.data,
    required this.onCopy,
    required this.onShare,
  });

  final MyReferralCodeModel data;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      glow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Your referral code',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  data.referralCode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.purpleSoft,
                ),
              ),
              IconButton(
                onPressed: onShare,
                icon: const Icon(
                  Icons.share_rounded,
                  color: AppColors.purpleSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(label: 'Referred', value: '${data.totalReferred}'),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Completed',
                value: '${data.completedReferrals}',
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Earned',
                value: '₹${data.totalEarned.toStringAsFixed(0)}',
              ),
            ],
          ),
          if (data.nextMilestoneAt != null) ...[
            const SizedBox(height: 14),
            Text(
              'Refer ${data.nextMilestoneAt} friends to unlock a '
              '₹${data.nextMilestoneBonus?.toStringAsFixed(0) ?? '—'} bonus',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassFillStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralHistoryTile extends StatelessWidget {
  const _ReferralHistoryTile({required this.item});
  final ReferralStatusItemModel item;

  Color _statusColor() {
    switch (item.status) {
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.live;
      case 'on_hold':
        return AppColors.gold;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.refereeName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.rewardCredited && item.rewardAmount != null
                      ? '₹${item.rewardAmount!.toStringAsFixed(0)} credited'
                      : item.status.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor().withValues(alpha: 0.4)),
            ),
            child: Text(
              item.status.replaceAll('_', ' '),
              style: TextStyle(
                color: _statusColor(),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          'No referrals yet. Share your code to start earning!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({this.height = 80});
  final double height;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: SizedBox(height: height),
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
