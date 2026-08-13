import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../models/payment_method_model.dart';
import '../providers/home_providers.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/withdrawal_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth/auth_primary_button.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/common/glass_container.dart';
import 'payment_methods_screen.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _amountCtrl = TextEditingController();
  PaymentMethodModel? _method;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMethod() async {
    final picked = await Navigator.of(context).push<PaymentMethodModel>(
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen(pickMode: true)),
    );
    if (picked != null) setState(() => _method = picked);
  }

  Future<void> _submit() async {
    final method = _method;
    if (method == null) {
      setState(() => _error = 'Select a payment method to withdraw to.');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await withdrawalService.requestWithdrawal(
        paymentMethodId: method.id,
        amount: amount,
      );
      ref.invalidate(walletProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal requested — it\'ll be processed shortly.')),
        );
        Navigator.of(context).pop(true);
      }
    } on UnauthenticatedException {
      setState(() => _error = 'Please log in to withdraw.');
    } catch (e) {
      setState(() => _error = 'Could not submit. Check the amount and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final available = walletAsync.valueOrNull?.availableBalance;

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
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Withdraw',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (available != null) ...[
                        Text(
                          'Available: ${formatRupees(available)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AuthTextField(
                        controller: _amountCtrl,
                        label: 'Amount (₹)',
                        hint: 'e.g. 500',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.currency_rupee_rounded,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Withdraw To',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickMethod,
                        child: GlassContainer(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(14),
                          child: _method == null
                              ? const Row(
                                  children: [
                                    Icon(Icons.add_card_rounded, color: AppColors.textMuted, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Select a payment method',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      _method!.methodType == PaymentMethodType.upi
                                          ? Icons.qr_code_rounded
                                          : Icons.account_balance_rounded,
                                      color: AppColors.purpleSoft,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _method!.accountHolderName,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            _method!.subtitle,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: AppColors.textMuted, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
                      ],
                      const SizedBox(height: 26),
                      AuthPrimaryButton(
                        label: 'Request Withdrawal',
                        loading: _submitting,
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
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
