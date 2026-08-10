import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../models/social.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Read-only view of another player's profile.
/// Backend: GET /social/profiles/{user_id} (app/api/v1/social_routes.py).
/// Report action posts to POST /reports with:
///   target_type = "player", target_id = user_id, reason, description
/// (app/models/moderation.py — Report / ReportTargetType / ReportReason).
class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _socialService = SocialService();

  bool _loading = true;
  String? _error;
  PlayerProfile? _profile;
  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _socialService.getProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _actionInFlight) return;
    setState(() => _actionInFlight = true);
    try {
      if (profile.isFollowing == true) {
        await _socialService.unfollow(widget.userId);
      } else {
        await _socialService.follow(widget.userId);
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  Future<void> _addFriend() async {
    if (_actionInFlight) return;
    setState(() => _actionInFlight = true);
    try {
      await _socialService.sendFriendRequest(widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Friend request sent'), backgroundColor: AppColors.success));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_error != null || _profile == null) {
      return Column(
        children: [
          _topBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                    const SizedBox(height: 12),
                    Text(_error ?? 'Could not load profile',
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    GradientButton(label: 'RETRY', onTap: _load, height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final profile = _profile!;
    final stats = profile.stats;
    final isSelf = profile.relationshipStatus == 'self';

    return Column(
      children: [
        _topBar(),
        const SizedBox(height: 16),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 12),
        Text(profile.displayLabel,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          stats?.currentRank != null
              ? 'Rank #${stats!.currentRank} · ${profile.followersCount} followers'
              : '${profile.followersCount} followers · ${profile.followingCount} following',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(profile.bio!,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 22),
        if (!isSelf)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: GradientButton(
                    label: profile.relationshipStatus == 'friend' ? 'FRIENDS' : 'ADD FRIEND',
                    height: 44,
                    onTap: (_actionInFlight || profile.relationshipStatus == 'friend') ? null : _addFriend,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _actionInFlight ? null : _toggleFollow,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(profile.isFollowing == true ? 'FOLLOWING' : 'FOLLOW',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                _StatCol(value: '${stats?.matchesPlayed ?? 0}', label: 'Matches'),
                const _VDiv(),
                _StatCol(value: '${stats?.matchesWon ?? 0}', label: 'Wins'),
                const _VDiv(),
                _StatCol(value: '${((stats?.winRate ?? 0) * 100).toStringAsFixed(1)}%', label: 'Win Rate'),
              ],
            ),
          ),
        ),
        const Spacer(),
        if (!isSelf)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: GestureDetector(
              onTap: () => _openReportSheet(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.flag_outlined, color: AppColors.danger, size: 16),
                  SizedBox(width: 6),
                  Text('Report this player',
                      style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
          const Spacer(),
          if (_profile != null && _profile!.relationshipStatus != 'self')
            GestureDetector(
              onTap: () => _openReportSheet(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgBottom,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(
        playerName: _profile?.displayLabel ?? 'this player',
        targetUserId: widget.userId,
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _VDiv extends StatelessWidget {
  const _VDiv();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 34, color: AppColors.cardBorder);
}

class _ReportSheet extends StatefulWidget {
  final String playerName;
  final String targetUserId;
  const _ReportSheet({required this.playerName, required this.targetUserId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _socialService = SocialService();
  ReportReason? _selected;
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _socialService.reportPlayer(
        targetUserId: widget.targetUserId,
        reason: _selected!,
        description: _descController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Report submitted. Our moderation team will review it.'), backgroundColor: AppColors.purple),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text('Report ${widget.playerName}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Target type: Player — same report table backend uses for teams and tournaments.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReportReason.values.map((r) {
                final selected = r == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                    ),
                    child: Text(r.label,
                        style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              maxLength: 2000,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add details (optional)',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.card,
                counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: _submitting ? 'SUBMITTING...' : 'SUBMIT REPORT',
              height: 48,
              width: double.infinity,
              onTap: (_selected == null || _submitting) ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
