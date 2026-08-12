# ClassyBattle — Tournaments + Tournament Details screens

This zip contains only the **new/changed files** for the two screens,
built to match the reference screenshots pixel-for-pixel in layout
while pulling every piece of content from your real FastAPI backend.
Drop these into your `Classybattle-app` repo at the same paths (this
mirrors `lib/` exactly) and they'll slot in next to your existing
Home screen code — nothing else was touched.

## What's new

**Screens**
- `lib/screens/tournaments_screen.dart` — Tournaments list screen (header, search+filter, tabs, Live/Upcoming/Your Tournaments)
- `lib/screens/tournament_details_screen.dart` — Tournament Details screen (hero, join, info, room, prize pool, rules)
- `lib/screens/home_screen.dart` — updated so the bottom-nav "Tournaments" tab and hero/section "View All"/Join taps now navigate into the two new screens instead of showing "coming soon"

**Models** (mirror the backend schemas exactly)
- `tournament_detail_model.dart` — full `TournamentRead` (rules, room_id/password, status, category, etc.)
- `game_mode_model.dart`, `map_model.dart` — resolve `mode_id`/`map_id` to real names
- `prize_pool_model.dart` — real per-rank payouts from `PrizePoolRead.distribution_rules`
- `participant_model.dart` — registration + prize-payout records, used for join-state and the Joined/Won/Winnings stats

**Service + providers**
- `services/tournament_service.dart` — talks to `/tournaments`, `/tournaments/{id}`, `/tournaments/{id}/join/solo`, `/tournaments/{id}/prize-pool`, `/tournaments/{id}/registration`, `/users/me/registrations`, `/prize-payouts/me`, `/game-modes/{id}`, `/maps/{id}`
- `providers/tournament_providers.dart` — tab state, search/filter state, and all the `FutureProvider`s the two screens read from

**Widgets**
- `widgets/tournaments/` — search+filter bar, status tabs, "Your Tournaments" stats row, generic filtered list (used by the Live/Upcoming/Completed/My Tournaments tabs)
- `widgets/tournament_details/` — hero banner, join section, info card, room details, prize pool, rules, and the inner-screen header bar

Your existing `home_service.dart`, `home_providers.dart`, `GlassContainer`, `NetworkImageBox`, `HeaderBar`, `BottomNavBar`, `LiveTournamentCard`, and `UpcomingTournamentRow` are reused as-is — no duplication, same visual language as your Home screen.

## Real data, no mock data

- Tournament list/detail, banner/cover images, prize pool, entry fee, player counts, room ID/password, and rules all come straight from the API responses — nothing is hardcoded.
- Fields the backend doesn't actually have (e.g. "Perspective"/"Region"/"Version" from the screenshot) are simply omitted from the Info card rather than invented.
- "Your Tournaments" (Joined / Won / Total Winnings) is computed from `/users/me/registrations` + `/prize-payouts/me` — real numbers, not the screenshot's 12/4/₹7,500.
- If a tournament has no configured prize pool, no room details yet, or no rules text, the UI shows a real "not available yet" state instead of fake numbers.

## One thing to double check on your end

I don't have a Flutter SDK / emulator in this environment (no network access to Google's Dart SDK download), so I could not run `flutter analyze` or `flutter run` against these files — I did a manual review (brace/paren balance, import correctness, provider/model field matching against your actual schemas) but you should run:

```
flutter analyze
flutter run
```

after copying the files in, and send me any errors — I'll fix them immediately. The most likely spots for a typo are the two biggest files: `tournaments_screen.dart` and `tournament_details_screen.dart`.

## Navigation wiring

- Bottom nav "Tournaments" (index 1) now pushes `TournamentsScreen` from `HomeScreen`, and pops back to Home from `TournamentsScreen`.
- Tapping a Live/Upcoming card (or its Join button) opens `TournamentDetailsScreen` for that tournament.
- The actual join action (wallet debit) happens on the Details screen's Join card, calling `POST /tournaments/{id}/join/solo`.
