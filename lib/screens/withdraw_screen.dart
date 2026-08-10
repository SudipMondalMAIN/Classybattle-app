import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../models/payment_method.dart';
import '../models/wallet.dart';
import '../models/withdrawal.dart';
import '../services/payment_method_service.dart';
import '../services/wallet_service.dart';
import '../services/withdrawal_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth/auth_widgets.dart';
import 'payment_methods_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _paymentMethodService = PaymentMethodService();
  final _withdrawalService = WithdrawalService();
  final _walletService = WalletService();

  bool _loading = true;
  String? _error;
  Wallet? _wallet;
  List<PaymentMethod> _methods = [];
  List<WithdrawalRequest> _history = [];
  PaymentMethod? _selectedMethod;

  final _amountController = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _walletService.getWallet(),
        _paymentMethodService.list(),
        _withdrawalService.myWithdrawals(pageSize: 20),
      ]);
      if (!mounted) return;
      final methods = results[1] as List<PaymentMethod>;
      setState(() {
        _wallet = results[0] as Wallet;
        _methods = methods;
        _history = results[2] as List<WithdrawalRequest>;
        _selectedMethod = methods.isNotEmpty ? methods.first : null;
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

  Future<void> _goAddMethod() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
    _load();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  Future<void> _submit() async {
    final method = _selectedMethod;
    final wallet = _wallet;
    if (method == null || wallet == null) return;
    if (_amount <= 0) {
      setState(() => _submitError = 'Enter a valid amount');
      return;
    }
    if (_amount > wallet.availableBalance) {
      setState(() => _submitError = 'Available balance er cheye beshi withdraw kora jabe na');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _withdrawalService.requestWithdrawal(paymentMethodId: method.id, amount: _amount);
      if (!mounted) return;
      _amountController.clear();
      showAuthSnack(context, 'Withdrawal request submitted!', isError: false);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    }
  }

  Future<void> _cancelRequest(WithdrawalRequest w) async {
    try {
      await _withdrawalService.cancel(w.id);
      if (!mounted) return;
      showAuthSnack(context, 'Withdrawal request cancelled', isError: false);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAuthSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 14),
                  const Text('Withdraw',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              GradientButton(label: 'RETRY', onTap: _load, height: 40),
            ],
          ),
        ),
      );
    }

    final wallet = _wallet!;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white, fontSize: 13)),
                Text('₹${formatMoney(wallet.availableBalance)}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Method',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: _goAddMethod,
                child: const Text('Manage', style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_methods.isEmpty)
            GestureDetector(
              onTap: _goAddMethod,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppColors.purple),
                    SizedBox(width: 10),
                    Text('Add a UPI or bank account to withdraw',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _methods
                  .map((m) => GestureDetector(
                        onTap: () => setState(() => _selectedMethod = m),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedMethod?.id == m.id ? AppColors.purple.withValues(alpha: 0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: _selectedMethod?.id == m.id ? AppColors.purple : AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                m.methodType == PaymentMethodType.upi ? Icons.qr_code_rounded : Icons.account_balance_rounded,
                                color: AppColors.purple,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(m.displayLabel,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              if (_selectedMethod?.id == m.id)
                                const Icon(Icons.check_circle_rounded, color: AppColors.purple, size: 18),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 16),
          const Text('Amount', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(color: AppColors.textPrimary),
              hintText: 'Enter amount',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.card,
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
          if (_submitError != null) ...[
            const SizedBox(height: 10),
            Text(_submitError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          GradientButton(
            label: _submitting ? 'SUBMITTING...' : 'REQUEST WITHDRAWAL',
            height: 52,
            width: double.infinity,
            onTap: (_submitting || _selectedMethod == null) ? null : _submit,
          ),
          const SizedBox(height: 28),
          const Text('Withdrawal History',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_history.isEmpty)
            const Text('No withdrawal requests yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            ..._history.map((w) => _HistoryTile(w: w, onCancel: w.status == WithdrawalStatus.pending ? () => _cancelRequest(w) : null)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final WithdrawalRequest w;
  final VoidCallback? onCancel;
  const _HistoryTile({required this.w, this.onCancel});

  Color get _statusColor {
    switch (w.status) {
      case WithdrawalStatus.completed:
        return AppColors.success;
      case WithdrawalStatus.pending:
        return AppColors.warning;
      case WithdrawalStatus.cancelled:
        return AppColors.textMuted;
      case WithdrawalStatus.rejected:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${formatMoney(w.amount)}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('#${w.txnNo}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          StatusPill(text: w.status.wire.toUpperCase(), color: _statusColor),
          if (onCancel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onCancel,
              child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
