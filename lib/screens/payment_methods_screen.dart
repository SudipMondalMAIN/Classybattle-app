import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../models/payment_method.dart';
import '../services/payment_method_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth/auth_widgets.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _service = PaymentMethodService();

  bool _loading = true;
  String? _error;
  List<PaymentMethod> _methods = [];

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
      final methods = await _service.list();
      if (!mounted) return;
      setState(() {
        _methods = methods;
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

  Future<void> _delete(PaymentMethod m) async {
    try {
      await _service.delete(m.id);
      if (!mounted) return;
      showAuthSnack(context, 'Payment method removed', isError: false);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAuthSnack(context, e.message);
    }
  }

  Future<void> _openAddDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddPaymentMethodDialog(),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBottom,
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
                  const Text('Payment Methods',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: GradientButton(label: 'ADD PAYMENT METHOD', height: 52, width: double.infinity, onTap: _openAddDialog),
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
    if (_methods.isEmpty) {
      return const Center(
        child: Text('No saved payment methods yet', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: _methods.length,
        itemBuilder: (context, i) {
          final m = _methods[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    m.methodType == PaymentMethodType.upi ? Icons.qr_code_rounded : Icons.account_balance_rounded,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.accountHolderName,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(m.displayLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(m),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(PaymentMethod m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Remove Payment Method?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('${m.displayLabel} remove korte chao?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(m);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _AddPaymentMethodDialog extends StatefulWidget {
  const _AddPaymentMethodDialog();

  @override
  State<_AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<_AddPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = PaymentMethodService();

  PaymentMethodType _type = PaymentMethodType.upi;
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_type == PaymentMethodType.upi) {
        await _service.createUpi(
          accountHolderName: _nameController.text.trim(),
          upiId: _upiController.text.trim(),
        );
      } else {
        await _service.createBankAccount(
          accountHolderName: _nameController.text.trim(),
          accountNumber: _accountController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _typeChip('UPI', PaymentMethodType.upi)),
                    const SizedBox(width: 10),
                    Expanded(child: _typeChip('Bank Account', PaymentMethodType.bankAccount)),
                  ],
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _nameController,
                  label: 'Account Holder Name',
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 14),
                if (_type == PaymentMethodType.upi)
                  AuthTextField(
                    controller: _upiController,
                    label: 'UPI ID (e.g. name@bank)',
                    validator: (v) =>
                        (v == null || !RegExp(r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$').hasMatch(v.trim()))
                            ? 'Enter a valid UPI ID'
                            : null,
                  )
                else ...[
                  AuthTextField(
                    controller: _accountController,
                    label: 'Account Number',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid account number' : null,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _ifscController,
                    label: 'IFSC Code',
                    validator: (v) => (v == null || !RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$').hasMatch(v.trim()))
                        ? 'Enter a valid IFSC code'
                        : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _saving
                          ? const Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                              ),
                            )
                          : GradientButton(label: 'Save', height: 44, onTap: _save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, PaymentMethodType type) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
