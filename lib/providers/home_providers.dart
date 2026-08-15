import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';
import '../models/game_model.dart';
import '../models/home_category_box_model.dart';
import '../models/tournament_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../services/home_service.dart';

/// Active promo banners for the hero carousel.
final bannersProvider = FutureProvider<List<BannerModel>>((ref) {
  return homeService.fetchBanners();
});

/// Active home-screen category boxes (Solo / Squad / Custom Tournament),
/// in sort order -- admin-managed, 3-per-row on the home screen.
final homeCategoryBoxesProvider = FutureProvider<List<HomeCategoryBoxModel>>((
  ref,
) {
  return homeService.fetchHomeCategoryBoxes();
});

/// All games, keyed by id, so cards can resolve a tournament's
/// game_id to a display name without embedding it redundantly.
final gamesByIdProvider = FutureProvider<Map<String, GameModel>>((ref) async {
  final games = await homeService.fetchGames();
  return {for (final g in games) g.id: g};
});

/// Currently live tournaments (status == live).
final liveTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) {
  return homeService.fetchTournaments(status: 'ongoing');
});

/// Scheduled / not-yet-live tournaments (status == scheduled). Excludes
/// user-hosted Custom Tournaments -- those have their own dedicated
/// browse page and should never appear in the home Upcoming rail.
final upcomingTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) {
  return homeService.fetchTournaments(status: 'upcoming', isCustom: false);
});

/// The featured upcoming tournament used to fill in the hero banner's
/// overlay (prize pool / registrations / CTA). Once a tournament goes
/// live it should stop showing on the home banner, so this only ever
/// looks at featured *upcoming* tournaments -- no live fallback.
final featuredLiveTournamentProvider = FutureProvider<TournamentModel?>((
  ref,
) async {
  final featured = await homeService.fetchTournaments(
    status: 'upcoming',
    isFeatured: true,
  );
  return featured.isNotEmpty ? featured.first : null;
});

/// Wallet balance for the header chip. Null means "not logged in" --
/// distinct from an actual zero balance -- so the UI can show a
/// login affordance instead of ₹0.
final walletProvider = FutureProvider<WalletModel?>((ref) async {
  try {
    return await homeService.fetchWallet();
  } on UnauthenticatedException {
    return null;
  }
});

/// Current user for the header avatar. Null means "not logged in".
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  try {
    return await homeService.fetchMe();
  } on UnauthenticatedException {
    return null;
  }
});
