import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_exception.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

enum _Step { amount, pay, verify }

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _paymentService = PaymentService();

  _Step _step = _Step.amount;
  bool _loadingSettings = true;
  String? _settingsError;
  PaymentSettings? _settings;

  int _selectedAmount = 100;
  final _customAmountController = TextEditingController();
  bool _useCustom = false;

  bool _generatingQr = false;
  DepositQuote? _quote;

  final _utrController = TextEditingController();
  XFile? _screenshot;
  bool _submitting = false;
  String? _submitError;

  static const _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loadingSettings = true;
      _settingsError = null;
    });
    try {
      final settings = await _paymentService.getSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loadingSettings = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _settingsError = e.message;
        _loadingSettings = false;
      });
    }
  }

  double get _amount {
    if (_useCustom) return double.tryParse(_customAmountController.text) ?? 0;
    return _selectedAmount.toDouble();
  }

  Future<void> _generateQr() async {
    final settings = _settings;
    final amount = _amount;
    if (settings != null) {
      if (amount < settings.minDepositAmount || amount > settings.maxDepositAmount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Amount must be between ₹${settings.minDepositAmount.toStringAsFixed(0)} and ₹${settings.maxDepositAmount.toStringAsFixed(0)}'),
          backgroundColor: AppColors.danger,
        ));
        return;
      }
    }
    setState(() => _generatingQr = true);
    try {
      final quote = await _paymentService.generateDepositQr(amount);
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _generatingQr = false;
        _step = _Step.pay;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _generatingQr = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _pickScreenshot() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _screenshot = picked);
  }

  Future<void> _submitDeposit() async {
    final quote = _quote;
    if (quote == null) return;
    if (_utrController.text.trim().isEmpty) {
      setState(() => _submitError = 'UTR / reference number is required');
      return;
    }
    if (_screenshot == null) {
      setState(() => _submitError = 'Please attach a payment screenshot');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _paymentService.submitDeposit(
        amount: quote.amount,
        utrNumber: _utrController.text.trim(),
        screenshotPath: _screenshot!.path,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deposit submitted! It will reflect once our team verifies it.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
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
                    onTap: () {
                      if (_step == _Step.amount) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _step = _Step.values[_step.index - 1]);
                      }
                    },
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 14),
                  const Text('Add Money',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            Expanded(child: _buildStepBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepBody() {
    if (_loadingSettings) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_settingsError != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 60, 18, 20),
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(_settingsError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Center(child: GradientButton(label: 'RETRY', onTap: _loadSettings, height: 40)),
        ],
      );
    }

    switch (_step) {
      case _Step.amount:
        return _buildAmountStep();
      case _Step.pay:
        return _buildPayStep();
      case _Step.verify:
        return _buildVerifyStep();
    }
  }

  Widget _buildAmountStep() {
    final settings = _settings!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      children: [
        const Text('Select Amount',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Min ₹${settings.minDepositAmount.toStringAsFixed(0)} · Max ₹${settings.maxDepositAmount.toStringAsFixed(0)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._quickAmounts.map((amt) {
              final selected = !_useCustom && amt == _selectedAmount;
              return GestureDetector(
                onTap: () => setState(() {
                  _useCustom = false;
                  _selectedAmount = amt;
                }),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 36 - 20) / 4,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: selected ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                  ),
                  child: Text('₹$amt',
                      style: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() => _useCustom = true),
              child: Container(
                width: (MediaQuery.of(context).size.width - 36 - 20) / 4,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _useCustom ? AppColors.primaryGradient : null,
                  color: _useCustom ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: _useCustom ? Colors.transparent : AppColors.cardBorder),
                ),
                child: Text('Other',
                    style: TextStyle(
                        color: _useCustom ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        if (_useCustom) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _customAmountController,
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
        ],
        const SizedBox(height: 26),
        if (!settings.isUpiEnabled)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: const Text('UPI deposits are temporarily disabled. Please try again later.',
                style: TextStyle(color: AppColors.warning, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildPayStep() {
    final quote = _quote!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      children: [
        const Text('Scan & Pay',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Pay ₹${quote.amount.toStringAsFixed(2)} to ${quote.merchantName}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 18),
        Center(
          child: Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black87),
                const SizedBox(height: 6),
                Text(quote.upiId, style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('UPI ID: ${quote.upiId}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        if (quote.note != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(quote.note!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Text(
            'After paying via any UPI app, tap "I\'ve Paid" and submit the UTR / reference number along with a screenshot for verification.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      children: [
        const Text('Confirm Your Payment',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _utrController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'UTR / Reference Number',
            labelStyle: const TextStyle(color: AppColors.textMuted),
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
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickScreenshot,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: _screenshot == null
                ? const Row(
                    children: [
                      Icon(Icons.upload_file_rounded, color: AppColors.purple),
                      SizedBox(width: 10),
                      Text('Attach payment screenshot',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  )
                : Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.file(File(_screenshot!.path), width: 44, height: 44, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_screenshot!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                    ],
                  ),
          ),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(_submitError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
      ],
    );
  }

  Widget? _buildBottomBar() {
    if (_step == _Step.amount) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: GradientButton(
          label: _generatingQr ? 'GENERATING...' : 'PROCEED TO PAY ₹${_amount == 0 ? '--' : _amount.toStringAsFixed(0)}',
          height: 52,
          width: double.infinity,
          fontSize: 15,
          onTap: (_generatingQr || _amount <= 0 || (_settings?.isUpiEnabled == false)) ? null : _generateQr,
        ),
      );
    }
    if (_step == _Step.pay) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: GradientButton(
          label: "I'VE PAID",
          height: 52,
          width: double.infinity,
          fontSize: 15,
          onTap: () => setState(() => _step = _Step.verify),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: GradientButton(
        label: _submitting ? 'SUBMITTING...' : 'SUBMIT FOR VERIFICATION',
        height: 52,
        width: double.infinity,
        fontSize: 15,
        onTap: _submitting ? null : _submitDeposit,
      ),
    );
  }
}
