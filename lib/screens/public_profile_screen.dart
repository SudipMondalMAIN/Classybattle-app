import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/social_model.dart';
import '../providers/social_providers.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/tournament_details/report_player_dialog.dart';

/// Another player's public profile -- reached by tapping a row on the
/// leaderboard. Shows name, uid, avatar, tournament/match *statistics*
/// only (no match/tournament history), Add Friend / Accept / Reject
/// friend-request actions, and a Report option.
class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _sendingRequest = false;
  bool _respondingRequest = false;
  ProfileRelationship? _relationshipOverride;
  String? _error;

  Future<void> _sendFriendRequest() async {
    setState(() {
      _sendingRequest = true;
      _error = null;
    });
    try {
      await socialService.sendFriendRequest(widget.userId);
      if (mounted) {
        setState(() => _relationshipOverride = ProfileRelationship.pending);
      }
    } on UnauthenticatedException {
      if (mounted) setState(() => _error = 'Please log in to add friends.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send request. Try again.');
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  Future<void> _acceptFriendRequest(String friendshipId) async {
    setState(() {
      _respondingRequest = true;
      _error = null;
    });
    try {
      await socialService.acceptFriendRequest(friendshipId);
      if (mounted) {
        setState(() => _relationshipOverride = ProfileRelationship.friend);
      }
    } on UnauthenticatedException {
      if (mounted) setState(() => _error = 'Please log in to manage friend requests.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not accept the request. Try again.');
    } finally {
      if (mounted) setState(() => _respondingRequest = false);
    }
  }

  Future<void> _rejectFriendRequest(String friendshipId) async {
    setState(() {
      _respondingRequest = true;
      _error = null;
    });
    try {
      await socialService.rejectFriendRequest(friendshipId);
      if (mounted) {
        setState(() => _relationshipOverride = ProfileRelationship.none);
      }
    } on UnauthenticatedException {
      if (mounted) setState(() => _error = 'Please log in to manage friend requests.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not reject the request. Try again.');
    } finally {
      if (mounted) setState(() => _respondingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicProfileProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGradientTop, AppColors.backgroundGradientBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Player Profile',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    profileAsync.maybeWhen(
                      data: (profile) => GestureDetector(
                        onTap: () => showReportPlayerDialog(
                          context,
                          userId: profile.userId,
                          playerName: profile.name,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.glassFill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.flag_outlined,
                              color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.purple,
                  backgroundColor: AppColors.background,
                  onRefresh: () async {
                    ref.invalidate(publicProfileProvider(widget.userId));
                    await Future.delayed(const Duration(milliseconds: 250));
                  },
                  child: profileAsync.when(
                    loading: () => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: CircularProgressIndicator(color: AppColors.purpleSoft)),
                      ],
                    ),
                    error: (e, __) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 160),
                        const Center(
                          child: Icon(Icons.error_outline_rounded,
                              color: AppColors.textMuted, size: 36),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Couldn\'t load this profile.\nIt may be private.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: OutlinedButton(
                            onPressed: () =>
                                ref.invalidate(publicProfileProvider(widget.userId)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.purpleSoft,
                              side: const BorderSide(color: AppColors.glassBorder),
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                    data: (profile) => _ProfileBody(
                      profile: profile,
                      relationshipOverride: _relationshipOverride,
                      sendingRequest: _sendingRequest,
                      respondingRequest: _respondingRequest,
                      error: _error,
                      onAddFriend: _sendFriendRequest,
                      onAccept: () {
                        final id = profile.friendshipId;
                        if (id != null) _acceptFriendRequest(id);
                      },
                      onReject: () {
                        final id = profile.friendshipId;
                        if (id != null) _rejectFriendRequest(id);
                      },
                    ),
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

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.relationshipOverride,
    required this.sendingRequest,
    required this.respondingRequest,
    required this.error,
    required this.onAddFriend,
    required this.onAccept,
    required this.onReject,
  });

  final PublicProfileModel profile;
  final ProfileRelationship? relationshipOverride;
  final bool sendingRequest;
  final bool respondingRequest;
  final String? error;
  final VoidCallback onAddFriend;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final relationship = relationshipOverride ?? profile.relationship;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.glassFillStrong,
            backgroundImage: profile.avatarUrl != null
                ? CachedNetworkImageProvider(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: AppColors.textSecondary)
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            profile.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (profile.user != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              'UID: ${profile.user!.playerUid}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
        ],
        if (profile.isOnline) ...[
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Online',
                    style: TextStyle(color: AppColors.success, fontSize: 12)),
              ],
            ),
          ),
        ],
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            profile.bio!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
        const SizedBox(height: 20),
        _FriendActionButton(
          relationship: relationship,
          loading: sendingRequest,
          responding: respondingRequest,
          onAddFriend: onAddFriend,
          onAccept: onAccept,
          onReject: onReject,
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(error!, style: const TextStyle(color: AppColors.live, fontSize: 12.5)),
          ),
        ],
        const SizedBox(height: 24),
        if (profile.stats != null) _StatsGrid(stats: profile.stats!),
        const SizedBox(height: 20),
        GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 18, color: AppColors.purpleSoft),
              const SizedBox(width: 10),
              Text(
                '${profile.friendsCount} friends · ${profile.followersCount} followers',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final PlayerStatsSummary stats;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.purple,
                  value: '${stats.tournamentsPlayed}',
                  label: 'Tournaments\nPlayed',
                ),
              ),
              _Divider(),
              Expanded(
                child: _Stat(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.gold,
                  value: '${stats.tournamentsWon}',
                  label: 'Tournaments\nWon',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.sports_esports_rounded,
                  iconColor: const Color(0xFF3DB4FF),
                  value: '${stats.matchesWon}/${stats.matchesPlayed}',
                  label: 'Matches\nWon',
                ),
              ),
              _Divider(),
              Expanded(
                child: _Stat(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppColors.success,
                  value: '${stats.winRate.round()}%',
                  label: 'Win Rate',
                ),
              ),
            ],
          ),
          if (stats.currentRank != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.leaderboard_rounded,
                    iconColor: AppColors.purpleSoft,
                    value: '#${stats.currentRank}',
                    label: 'Global\nRank',
                  ),
                ),
                _Divider(),
                Expanded(
                  child: _Stat(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFFF9F43),
                    value: stats.kdRatio.toStringAsFixed(2),
                    label: 'K/D\nRatio',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: AppColors.glassBorder);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.2),
        ),
      ],
    );
  }
}

class _FriendActionButton extends StatelessWidget {
  const _FriendActionButton({
    required this.relationship,
    required this.loading,
    required this.responding,
    required this.onAddFriend,
    required this.onAccept,
    required this.onReject,
  });

  final ProfileRelationship relationship;
  final bool loading;
  final bool responding;
  final VoidCallback onAddFriend;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    switch (relationship) {
      case ProfileRelationship.self_:
        return const SizedBox.shrink();
      case ProfileRelationship.friend:
        return _pill(
          icon: Icons.check_circle_rounded,
          label: 'Friends',
          color: AppColors.success,
        );
      case ProfileRelationship.pending:
        return _pill(
          icon: Icons.hourglass_top_rounded,
          label: 'Request Pending',
          color: AppColors.textSecondary,
        );
      case ProfileRelationship.incoming:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: responding ? null : onReject,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.glassBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: responding ? null : onAccept,
                icon: responding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(responding ? 'Please wait...' : 'Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        );
      case ProfileRelationship.blocked:
        return _pill(
          icon: Icons.block_rounded,
          label: 'Unavailable',
          color: AppColors.textMuted,
        );
      case ProfileRelationship.none:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onAddFriend,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(loading ? 'Sending...' : 'Add Friend'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
    }
  }

  Widget _pill({required IconData icon, required String label, required Color color}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
