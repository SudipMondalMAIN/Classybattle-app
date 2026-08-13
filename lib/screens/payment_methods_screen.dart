import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_method_model.dart';
import '../providers/payment_providers.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/payment_method_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth/auth_primary_button.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/common/glass_container.dart';

/// Lets the user pick (or add) a saved UPI/bank withdrawal
/// destination. Pops with the selected [PaymentMethodModel] when used
/// in "pick" mode from the Withdraw screen.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMethodSheet(),
    );
    if (added == true) {
      ref.invalidate(paymentMethodsProvider);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await paymentMethodService.deleteMethod(id);
      ref.invalidate(paymentMethodsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove this method.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

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
                    Text(
                      widget.pickMode ? 'Select Payment Method' : 'Payment Methods',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: methodsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.purpleSoft),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      'Couldn\'t load payment methods',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  data: (methods) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      children: [
                        if (methods.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No payment methods added yet',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          ),
                        for (final m in methods)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: widget.pickMode
                                  ? () => Navigator.of(context).pop(m)
                                  : null,
                              child: GlassContainer(
                                borderRadius: 16,
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.16),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        m.methodType == PaymentMethodType.upi
                                            ? Icons.qr_code_rounded
                                            : Icons.account_balance_rounded,
                                        color: AppColors.purpleSoft,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.accountHolderName,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            m.subtitle,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!widget.pickMode)
                                      GestureDetector(
                                        onTap: () => _delete(m.id),
                                        child: const Icon(Icons.delete_outline_rounded,
                                            color: AppColors.textMuted, size: 20),
                                      )
                                    else
                                      const Icon(Icons.chevron_right_rounded,
                                          color: AppColors.textMuted, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _openAddSheet,
                          child: DottedBorderAdd(),
                        ),
                      ],
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

class DottedBorderAdd extends StatelessWidget {
  DottedBorderAdd({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorderBright, width: 1.4),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: AppColors.purpleSoft, size: 20),
          SizedBox(width: 6),
          Text(
            'Add Payment Method',
            style: TextStyle(
              color: AppColors.purpleSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMethodSheet extends StatefulWidget {
  const _AddMethodSheet();

  @override
  State<_AddMethodSheet> createState() => _AddMethodSheetState();
}

class _AddMethodSheetState extends State<_AddMethodSheet> {
  PaymentMethodType _type = PaymentMethodType.upi;
  final _nameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _upiCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter the account holder name.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      if (_type == PaymentMethodType.upi) {
        if (_upiCtrl.text.trim().isEmpty) {
          setState(() => _error = 'Enter a valid UPI ID.');
          return;
        }
        await paymentMethodService.addUpiMethod(
          accountHolderName: _nameCtrl.text.trim(),
          upiId: _upiCtrl.text.trim(),
        );
      } else {
        if (_accountCtrl.text.trim().isEmpty || _ifscCtrl.text.trim().isEmpty) {
          setState(() => _error = 'Enter account number and IFSC code.');
          return;
        }
        await paymentMethodService.addBankMethod(
          accountHolderName: _nameCtrl.text.trim(),
          accountNumber: _accountCtrl.text.trim(),
          ifscCode: _ifscCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on UnauthenticatedException {
      setState(() => _error = 'Please log in first.');
    } catch (e) {
      setState(() => _error = 'Could not save. Check the details and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.backgroundGradientBottom,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorderBright,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Payment Method',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: 'UPI',
                      selected: _type == PaymentMethodType.upi,
                      onTap: () => setState(() => _type = PaymentMethodType.upi),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeChip(
                      label: 'Bank Account',
                      selected: _type == PaymentMethodType.bank,
                      onTap: () => setState(() => _type = PaymentMethodType.bank),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _nameCtrl,
                label: 'Account Holder Name',
                hint: 'Full name as per bank/UPI',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              if (_type == PaymentMethodType.upi)
                AuthTextField(
                  controller: _upiCtrl,
                  label: 'UPI ID',
                  hint: 'name@bank',
                  prefixIcon: Icons.qr_code_rounded,
                )
              else ...[
                AuthTextField(
                  controller: _accountCtrl,
                  label: 'Account Number',
                  hint: 'Bank account number',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.numbers_rounded,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _ifscCtrl,
                  label: 'IFSC Code',
                  hint: 'e.g. SBIN0001234',
                  prefixIcon: Icons.account_balance_rounded,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Save',
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.glassBorder,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.purpleSoft : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
