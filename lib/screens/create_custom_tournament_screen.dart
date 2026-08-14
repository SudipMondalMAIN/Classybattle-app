import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../services/tournament_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import 'tournament_details_screen.dart';

/// Platform commission on user-hosted custom tournaments -- mirrors
/// TournamentService.PLATFORM_COMMISSION_RATE on the backend. Used only
/// to show a live "you'll receive ~₹x" preview; the real prize_pool is
/// always computed server-side.
const double _kPlatformCommissionRate = 0.175;

class CreateCustomTournamentScreen extends ConsumerStatefulWidget {
  const CreateCustomTournamentScreen({super.key});

  @override
  ConsumerState<CreateCustomTournamentScreen> createState() =>
      _CreateCustomTournamentScreenState();
}

class _CreateCustomTournamentScreenState
    extends ConsumerState<CreateCustomTournamentScreen> {
  final _titleCtrl = TextEditingController();
  final _entryFeeCtrl = TextEditingController(text: '10');
  final _maxPlayersCtrl = TextEditingController(text: '2');

  String? _gameId;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _entryFeeCtrl.dispose();
    _maxPlayersCtrl.dispose();
    super.dispose();
  }

  double get _entryFee => double.tryParse(_entryFeeCtrl.text.trim()) ?? 0;
  int get _maxPlayers => int.tryParse(_maxPlayersCtrl.text.trim()) ?? 0;

  double get _totalPool => _entryFee * _maxPlayers;
  double get _prizePool => _totalPool * (1 - _kPlatformCommissionRate);

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.length < 3) {
      setState(() => _error = 'Title must be at least 3 characters.');
      return;
    }
    if (_gameId == null) {
      setState(() => _error = 'Please select a game.');
      return;
    }
    if (_entryFee <= 0) {
      setState(() => _error = 'Entry fee must be greater than 0.');
      return;
    }
    if (_maxPlayers < 2) {
      setState(() => _error = 'Need at least 2 players.');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final tournament = await tournamentService.createCustomTournament(
        title: title,
        gameId: _gameId!,
        entryFee: _entryFee,
        maxPlayers: _maxPlayers,
      );
      if (!mounted) return;
      ref.invalidate(allTournamentsProvider);
      ref.invalidate(liveTournamentsCountProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(myRegistrationProvider(tournament.id));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              TournamentDetailsScreen(tournamentId: tournament.id),
        ),
      );
    } on CreateTournamentException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not create the tournament. Try again.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesByIdProvider);

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
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                    const Text(
                      'Custom Tournament',
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    const _FieldLabel('Tournament Title'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _titleCtrl,
                      hint: 'e.g. Friday Night Squad Fight',
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Game'),
                    const SizedBox(height: 8),
                    gamesAsync.when(
                      data: (games) => _GamePicker(
                        games: games.values.toList(),
                        selectedId: _gameId,
                        onSelect: (id) => setState(() => _gameId = id),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.purple),
                        ),
                      ),
                      error: (_, __) => const Text(
                        'Could not load games.',
                        style: TextStyle(color: AppColors.live, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Entry Fee (₹)'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _entryFeeCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Players'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _maxPlayersCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _PrizePreview(
                      totalPool: _totalPool,
                      prizePool: _prizePool,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You\'ll be auto-joined as the first player and your '
                      'wallet will be charged the entry fee.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!,
                          style: const TextStyle(
                              color: AppColors.live, fontSize: 12)),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleButton,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _creating ? null : _create,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _creating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Create Tournament',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _GamePicker extends StatelessWidget {
  const _GamePicker({
    required this.games,
    required this.selectedId,
    required this.onSelect,
  });

  final List<GameModel> games;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const Text(
        'No games available right now.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: games.map((g) {
        final selected = g.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(g.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: selected ? AppColors.purpleButton : null,
              color: selected ? null : AppColors.glassFill,
              border: Border.all(
                color: selected ? Colors.transparent : AppColors.glassBorder,
              ),
            ),
            child: Text(
              g.name,
              style: TextStyle(
                color:
                    selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PrizePreview extends StatelessWidget {
  const _PrizePreview({required this.totalPool, required this.prizePool});

  final double totalPool;
  final double prizePool;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Pool',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalPool.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.glassBorder),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Winner Gets',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${prizePool.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
