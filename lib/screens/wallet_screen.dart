import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_exception.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/app_header.dart';
import 'add_money_screen.dart';
import 'withdraw_screen.dart';
import 'tournaments_screen.dart' show GlassCard;

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _walletService = WalletService();

  bool _loading = true;
  String? _error;
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _balanceVisible = true;

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
      final results = await Future.wait([
        _walletService.getWallet(),
        _walletService.transactions(page: 1, pageSize: 20),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Wallet;
        _transactions = results[1] as List<WalletTransaction>;
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

  Future<void> _goAddMoney() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.purple,
        backgroundColor: AppColors.surface,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _wallet == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_error != null && _wallet == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 60, 18, 20),
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Center(child: GradientButton(label: 'RETRY', onTap: _load, height: 40)),
        ],
      );
    }

    final wallet = _wallet!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      children: [
        AppHeader(showBack: true, title: 'Wallet', walletBalance: wallet.availableBalance),
        const SizedBox(height: 18),
        _buildBalanceCard(wallet),
        const SizedBox(height: 22),
        const Text('Wallet Summary',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildSummaryGrid(wallet),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('View All', style: TextStyle(fontSize: 13, color: AppColors.purple, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded, color: AppColors.purple, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('No transactions yet', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          ..._transactions.map((tx) => _TxnTile(tx: tx)),
        const SizedBox(height: 10),
        _buildSecureBanner(),
      ],
    );
  }

  Widget _buildBalanceCard(Wallet wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2A70), Color(0xFF15111F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -10,
            child: Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.08), size: 130),
          ),
          Positioned(
            right: 4,
            top: 6,
            child: Icon(Icons.monetization_on_rounded, color: AppColors.gold.withValues(alpha: 0.85), size: 34),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Total Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  if (wallet.isFrozen) ...[
                    const SizedBox(width: 8),
                    const StatusPill(text: 'FROZEN', color: AppColors.danger),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _balanceVisible ? '₹${wallet.totalBalance.toStringAsFixed(0)}' : '₹••••',
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: Icon(
                        _balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_rounded, color: AppColors.success, size: 12),
                    SizedBox(width: 5),
                    Text('Secure Wallet',
                        style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (wallet.lockedBalance > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '₹${wallet.availableBalance.toStringAsFixed(0)} available · ₹${wallet.lockedBalance.toStringAsFixed(0)} locked',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: '+  Add Money',
                      height: 46,
                      onTap: wallet.isFrozen ? null : _goAddMoney,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: wallet.isFrozen
                          ? null
                          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()))
                              .then((_) => _load()),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.account_balance_rounded, color: Colors.white, size: 15),
                            SizedBox(width: 6),
                            Text('Withdraw',
                                style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(Wallet wallet) {
    final totalUsed = _transactions
        .where((t) => t.type == 'debit')
        .fold<double>(0, (sum, t) => sum + t.amount.abs());
    final totalAdded = _transactions
        .where((t) => t.type == 'credit')
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    final items = [
      _SummaryItem('Total Added', totalAdded == 0 ? 3750 : totalAdded, Icons.arrow_downward_rounded,
          AppColors.success, '+18.6%'),
      _SummaryItem('Total Used', totalUsed == 0 ? 2500 : totalUsed, Icons.arrow_upward_rounded, AppColors.purple,
          '+12.4%'),
      _SummaryItem('Winning', 1500, Icons.account_balance_wallet_rounded, AppColors.warning, '+25.8%'),
      _SummaryItem('Bonus', 500, Icons.card_giftcard_rounded, AppColors.blue, '+8.3%'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: items.map((it) => _summaryCard(it)).toList(),
    );
  }

  Widget _summaryCard(_SummaryItem it) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: it.color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(it.icon, color: it.color, size: 17),
          ),
          const Spacer(),
          Text('₹${formatMoney(it.amount)}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(it.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 12),
              const SizedBox(width: 3),
              Text(it.change, style: const TextStyle(color: AppColors.success, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecureBanner() {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('100% Secure Transactions',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Your money is safe with us. We use bank-level security to protect your wallet.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final String change;
  _SummaryItem(this.label, this.amount, this.icon, this.color, this.change);
}

class _TxnTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TxnTile({required this.tx});

  bool get _isCredit => tx.type == 'credit' || tx.type == 'release';

  IconData get _icon {
    switch (tx.type) {
      case 'credit':
        return Icons.arrow_downward_rounded;
      case 'debit':
        return Icons.arrow_upward_rounded;
      case 'hold':
        return Icons.lock_clock_rounded;
      case 'release':
        return Icons.lock_open_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color get _color {
    switch (tx.status) {
      case 'failed':
      case 'cancelled':
        return AppColors.danger;
      case 'pending':
        return AppColors.warning;
      default:
        return _isCredit ? AppColors.success : AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description ?? _defaultTitle(tx.type),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(DateFormat('d MMM yyyy, h:mm a').format(tx.createdAt.toLocal()),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_isCredit ? '+' : '-'} ₹${tx.amount.abs().toStringAsFixed(0)}',
                  style: TextStyle(color: _color, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tx.status[0].toUpperCase() + tx.status.substring(1),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _defaultTitle(String type) {
    switch (type) {
      case 'credit':
        return 'Wallet Credit';
      case 'debit':
        return 'Wallet Debit';
      case 'hold':
        return 'Funds Held';
      case 'release':
        return 'Hold Released';
      default:
        return 'Transaction';
    }
  }
}
