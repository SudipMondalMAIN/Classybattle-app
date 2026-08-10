import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/glass.dart';
import 'home_screen.dart';
import 'tournaments_screen.dart';
import 'leaderboard_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    TournamentsScreen(),
    LeaderboardScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: BottomNav(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}
