import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_exception.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_money_screen.dart';

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
          Center(
            child: GradientButton(label: 'RETRY', onTap: _load, height: 40),
          ),
        ],
      );
    }

    final wallet = _wallet!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      children: [
        Row(
          children: [
            const Text('Wallet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.textPrimary, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3A1A6B), Color(0xFF1A1330)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
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
              const SizedBox(height: 6),
              Text('₹${wallet.totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
              if (wallet.lockedBalance > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '₹${wallet.availableBalance.toStringAsFixed(2)} available · ₹${wallet.lockedBalance.toStringAsFixed(2)} locked',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: 'ADD MONEY',
                      height: 44,
                      onTap: wallet.isFrozen ? null : _goAddMoney,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Withdrawals coming soon')),
                        );
                      },
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Text('WITHDRAW',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Transaction History'),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text('No transactions yet', style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ..._transactions.map((tx) => _TxnTile(tx: tx)),
      ],
    );
  }
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
        color: AppColors.card,
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
                Text(DateFormat('d MMM, h:mm a').format(tx.createdAt.toLocal()),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_isCredit ? '+' : '-'} ₹${tx.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(color: _color, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tx.status, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
