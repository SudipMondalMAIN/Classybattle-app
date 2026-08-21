import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';

class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

const _faqItems = <_FaqItem>[
  _FaqItem(
    'What is ClassyBattle?',
    'ClassyBattle is a competitive eSports tournament platform. Join solo '
        'or squad tournaments across supported games, compete for room '
        'slots, and win real cash prizes based on your performance.',
  ),
  _FaqItem(
    'How do I join a tournament?',
    'Open a tournament from the Tournaments tab and tap Join. If it has an '
        'entry fee, the amount is deducted from your ClassyBattle wallet '
        'once you confirm — make sure your wallet balance covers it first.',
  ),
  _FaqItem(
    'How do I add money to my wallet?',
    'Go to Wallet > Add Money, choose a payment method, and complete the '
        'payment. Your balance updates as soon as the payment is confirmed. '
        'If a payment succeeds but your balance doesn\'t update, check '
        'Wallet > Transactions before contacting support.',
  ),
  _FaqItem(
    'How do withdrawals work?',
    'Go to Wallet > Withdraw, enter an amount (the screen shows the '
        'current minimum and maximum), and submit. Withdrawals are '
        'reviewed and approved by our team, so payout isn\'t instant — '
        'track the status under Wallet > Transactions.',
  ),
  _FaqItem(
    'When and how do I get room ID/password?',
    'Room details are published on the Tournament Details screen shortly '
        'before the match starts, once the organizer sets them. You\'ll '
        'also get a notification when they\'re ready — no room details '
        'are shared over chat or email.',
  ),
  _FaqItem(
    'How are winners and prizes decided?',
    'Match results are recorded after the match and reviewed before a '
        'winner is confirmed. Prize payouts follow the prize pool shown on '
        'the tournament\'s details screen and are credited to your wallet '
        'once results are approved.',
  ),
  _FaqItem(
    'I think I was wrongly reported/penalized. What can I do?',
    'Use Report a Problem in Settings > Support to describe what happened, '
        'or start a Live Chat with our support team — every report is '
        'reviewed manually.',
  ),
  _FaqItem(
    'How do I contact support?',
    'Settings > Support has two options: Live Chat Support for a real-time '
        'conversation with our team, and Report a Problem for issues that '
        'need a written report with details/screenshots.',
  ),
];

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                    const Text(
                      'FAQ',
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
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: _faqItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _faqItems[i];
                    final expanded = _expandedIndex == i;
                    return GlassContainer(
                      borderRadius: 16,
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => setState(
                              () => _expandedIndex = expanded ? null : i,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.question,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: expanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 180),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 180),
                            crossFadeState: expanded
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                item.answer,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            secondChild: const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
