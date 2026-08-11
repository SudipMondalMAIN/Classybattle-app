import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../core/api_exception.dart';
import '../core/game_cache.dart';
import '../providers/auth_provider.dart';
import '../models/game.dart';
import '../models/participant.dart';
import '../models/tournament.dart';
import '../models/leaderboard.dart';
import '../models/wallet.dart';
import '../services/tournament_service.dart';
import '../services/leaderboard_service.dart';
import '../services/wallet_service.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import 'auth/login_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'wallet_screen.dart';
import 'add_money_screen.dart';
import 'game_profiles_screen.dart';
import 'withdraw_screen.dart';
import 'tournament_detail_screen.dart';

class _MyEntry {
  final Participant participant;
  final Tournament tournament;
  _MyEntry(this.participant, this.tournament);
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _tournamentService = TournamentService();
  final _leaderboardService = LeaderboardService();
  final _walletService = WalletService();

  bool _loading = true;
  String? _error;
  PlayerStatistics? _stats;
  Wallet? _wallet;
  List<_MyEntry> _entries = [];
  Map<String, Game> _games = {};
  int _tab = 0; // Joined | Upcoming | Completed | Cancelled

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
      await ref.read(authControllerProvider.notifier).refreshUser();
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw ApiException('Not logged in');

      final results = await Future.wait([
        _leaderboardService.getPlayerStatistics(user.id).catchError((e) {
          // New accounts don't have a stats row yet — treat "not found" as
          // zero stats instead of failing the whole profile screen.
          if (e is ApiException && e.statusCode == 404) {
            return PlayerStatistics.empty(user.id);
          }
          throw e;
        }),
        _walletService.getWallet(),
        _tournamentService.myRegistrations(pageSize: 50),
        GameCache.instance.byId(),
      ]);

      final stats = results[0] as PlayerStatistics;
      final wallet = results[1] as Wallet;
      final registrations = results[2] as List<Participant>;
      final games = results[3] as Map<String, Game>;

      final tournamentIds = registrations.map((p) => p.tournamentId).toSet().toList();
      final tournaments = await Future.wait(tournamentIds.map((id) => _tournamentService.getById(id)));
      final tournamentsById = {for (final t in tournaments) t.id: t};

      final entries = registrations
          .where((p) => tournamentsById.containsKey(p.tournamentId))
          .map((p) => _MyEntry(p, tournamentsById[p.tournamentId]!))
          .toList()
        ..sort((a, b) => b.participant.joinedAt.compareTo(a.participant.joinedAt));

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _wallet = wallet;
        _entries = entries;
        _games = games;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong: $e';
        _loading = false;
      });
    }
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

  List<_MyEntry> get _filtered {
    switch (_tab) {
      case 1:
        return _entries.where((e) => e.tournament.status == 'scheduled' || e.tournament.status == 'live').toList();
      case 2:
        return _entries.where((e) => e.tournament.status == 'completed').toList();
      case 3:
        return _entries.where((e) => e.tournament.status == 'cancelled').toList();
      default:
        return _entries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.purple,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          children: [
            _topBar(),
            const SizedBox(height: 20),
            if (user != null)
              _profileCard(user.fullName, user.playerUid, user.avatarId, user.isEmailVerified)
            else
              _profileCardSkeleton(),
            const SizedBox(height: 22),
            if (_loading)
              _skeletonBody()
            else if (_error != null)
              _errorState()
            else ...[
              _statsRow(),
              const SizedBox(height: 22),
              _myTournamentsHeader(),
              const SizedBox(height: 12),
              _tabsBar(),
              const SizedBox(height: 14),
              ..._tournamentCards(),
              const SizedBox(height: 22),
              _accountSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.purple, size: 15),
                const SizedBox(width: 6),
                Text(_wallet == null ? '₹ —' : '₹ ${formatMoney(_wallet!.availableBalance)}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _iconButton(Icons.notifications_none_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
        const SizedBox(width: 10),
        _iconButton(Icons.settings_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ],
    );
  }

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  Widget _profileCard(String name, String uid, String? avatarId, bool verified) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            avatarId: avatarId,
            fallbackInitial: name.isNotEmpty ? name[0].toUpperCase() : '?',
            size: 70,
            onEditTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: AppColors.purple, size: 17),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('UID copied'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: Row(
                    children: [
                      Text('UID: $uid', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(width: 5),
                      const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.purple, size: 13),
                  SizedBox(width: 5),
                  Text('Edit Profile', style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBody() {
    return Column(
      children: [
        // stats row skeleton
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Column(
                  children: [
                    const SkeletonCircle(size: 28),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 30, height: 12),
                    const SizedBox(height: 6),
                    SkeletonBox(width: i.isEven ? 50 : 40, height: 9),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const SkeletonBox(width: 130, height: 16),
            const Spacer(),
            const SkeletonBox(width: 60, height: 12),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(4, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SkeletonBox(width: 70, height: 30, radius: AppRadius.pill),
            );
          }),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 46, height: 46, radius: AppRadius.sm),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 140, height: 13),
                      SizedBox(height: 8),
                      SkeletonBox(width: 80, height: 10),
                      SizedBox(height: 10),
                      SkeletonBox(width: 100, height: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const SkeletonBox(width: 60, height: 22, radius: AppRadius.pill),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SkeletonBox(width: 90, height: 16),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: List.generate(6, (i) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: i == 5 ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    const SkeletonCircle(size: 19),
                    const SizedBox(width: 14),
                    const Expanded(child: SkeletonBox(height: 12)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _profileCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 70),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 120, height: 16),
                SizedBox(height: 10),
                SkeletonBox(width: 90, height: 12),
              ],
            ),
          ),
          const SkeletonBox(width: 90, height: 30, radius: AppRadius.pill),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 36),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final s = _stats;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _stat(Icons.emoji_events_rounded, AppColors.purple, '${s?.tournamentsPlayed ?? 0}', 'Tournaments\nJoined'),
          _vDivider(),
          _stat(Icons.star_rounded, AppColors.gold, '${s?.tournamentsWon ?? 0}', 'Tournaments\nWon'),
          _vDivider(),
          _stat(Icons.account_balance_wallet_rounded, AppColors.success, '₹${formatMoney(s?.walletEarnings ?? 0)}', 'Total\nWinnings'),
          _vDivider(),
          _stat(Icons.workspace_premium_rounded, AppColors.blue, '${((s?.winRate ?? 0)).toStringAsFixed(0)}%', 'Win Rate'),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, Color color, String value, String label) => Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.2)),
          ],
        ),
      );

  Widget _vDivider() => Container(width: 1, height: 46, color: AppColors.cardBorder);

  Widget _myTournamentsHeader() {
    return Row(
      children: [
        const Text('My Tournaments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const Spacer(),
        Text('${_entries.length} total', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _tabsBar() {
    final labels = ['Joined', 'Upcoming', 'Completed', 'Cancelled'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == _tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _tournamentCards() {
    final list = _filtered;
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 26),
          child: Center(
            child: Text('No ${_tab == 1 ? 'upcoming' : _tab == 2 ? 'completed' : _tab == 3 ? 'cancelled' : 'joined'} tournaments',
                style: const TextStyle(color: AppColors.textMuted)),
          ),
        )
      ];
    }
    return list
        .map((e) => _TournamentTile(
              entry: e,
              gameName: _games[e.tournament.gameId]?.name ?? 'Unknown',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: e.tournament.id)),
              ).then((_) => _load()),
            ))
        .toList();
  }

  Widget _accountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _menuRow(context, Icons.account_balance_wallet_rounded, 'Wallet',
                  trailing: _wallet == null ? null : '₹ ${formatMoney(_wallet!.availableBalance)}',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
              _menuRow(context, Icons.person_rounded, 'Edit Profile',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
              _menuRow(context, Icons.videogame_asset_rounded, 'Game Profiles',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameProfilesScreen()))),
              _menuRow(context, Icons.shield_rounded, 'Security', trailing: 'Change Password',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(openSecurity: true)))),
              _menuRow(context, Icons.history_rounded, 'Transaction History',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
              _menuRow(context, Icons.account_balance_wallet_outlined, 'Withdraw',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()))),
              _menuRow(context, Icons.add_card_rounded, 'Add Money',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMoneyScreen()))),
              _menuRow(context, Icons.help_outline_rounded, 'Help & Support',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(openSupport: true)))),
              _menuRow(context, Icons.info_outline_rounded, 'About ClassyBattle',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(openAbout: true))),
                  isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
    );
  }

  Widget _menuRow(BuildContext context, IconData icon, String label,
      {String? trailing, VoidCallback? onTap, bool isLast = false}) {
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
              child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (trailing != null) ...[
              Text(trailing, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 19),
          ],
        ),
      ),
    );
  }
}

class _TournamentTile extends StatelessWidget {
  final _MyEntry entry;
  final String gameName;
  final VoidCallback onTap;
  const _TournamentTile({required this.entry, required this.gameName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = entry.tournament;
    final p = entry.participant;
    final style = TournamentStatusStyle.of(t.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameIcon(game: gameName, size: 46, imageUrl: t.coverUrl ?? t.bannerUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(gameName, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  Text('${t.currentPlayers} / ${t.maxPlayers} Joined',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(text: style.label, color: style.color),
                const SizedBox(height: 8),
                Text(p.status[0].toUpperCase() + p.status.substring(1),
                    style: const TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
