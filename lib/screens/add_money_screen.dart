import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/formatters.dart';
import '../models/deposit_model.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth/auth_primary_button.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/common/glass_container.dart';

/// Step 1: enter an amount -> backend returns a real
/// `upi://pay?pa=<upi_id>&am=<amount>&cu=INR` payload, rendered as a
/// scannable QR. Step 2: after paying, the user submits the UTR and a
/// payment screenshot for admin verification.
class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _amountCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();
  DepositQrModel? _qr;
  File? _screenshot;
  bool _loadingQr = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateQr() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    setState(() {
      _error = null;
      _loadingQr = true;
    });
    try {
      final qr = await paymentService.generateDepositQr(amount);
      setState(() => _qr = qr);
    } on UnauthenticatedException {
      setState(() => _error = 'Please log in to add money.');
    } catch (e) {
      setState(() => _error = 'Could not generate QR. Try again.');
    } finally {
      if (mounted) setState(() => _loadingQr = false);
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _screenshot = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final qr = _qr;
    if (qr == null) return;
    if (_utrCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter the UTR / reference number.');
      return;
    }
    if (_screenshot == null) {
      setState(() => _error = 'Attach a screenshot of the payment.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await paymentService.submitDeposit(
        amount: qr.amount,
        utrNumber: _utrCtrl.text.trim(),
        screenshot: _screenshot!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted! We\'ll verify and credit your wallet shortly.')),
        );
        Navigator.of(context).pop(true);
      }
    } on UnauthenticatedException {
      setState(() => _error = 'Please log in to add money.');
    } catch (e) {
      setState(() => _error = 'Submission failed. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'Add Money',
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
                      if (_qr == null) ...[
                        AuthTextField(
                          controller: _amountCtrl,
                          label: 'Amount (₹)',
                          hint: 'e.g. 500',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.currency_rupee_rounded,
                          onSubmitted: (_) => _generateQr(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        AuthPrimaryButton(
                          label: 'Generate QR',
                          loading: _loadingQr,
                          onPressed: _loadingQr ? null : _generateQr,
                        ),
                      ] else ...[
                        _QrCard(qr: _qr!),
                        const SizedBox(height: 20),
                        const Text(
                          'Paid? Confirm below',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _utrCtrl,
                          label: 'UTR / Reference Number',
                          hint: '12-digit UPI transaction ref',
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.confirmation_number_outlined,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickScreenshot,
                          child: GlassContainer(
                            borderRadius: 14,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(
                                  _screenshot == null
                                      ? Icons.upload_file_rounded
                                      : Icons.check_circle_rounded,
                                  color: _screenshot == null
                                      ? AppColors.textMuted
                                      : AppColors.success,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _screenshot == null
                                        ? 'Attach payment screenshot'
                                        : 'Screenshot attached',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        AuthPrimaryButton(
                          label: 'Submit for Verification',
                          loading: _submitting,
                          onPressed: _submitting ? null : _submit,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() {
                              _qr = null;
                              _screenshot = null;
                              _utrCtrl.clear();
                            }),
                            child: const Text(
                              'Change amount',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
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

class _QrCard extends StatelessWidget {
  const _QrCard({required this.qr});

  final DepositQrModel qr;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      glow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            formatRupees(qr.amount),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan with any UPI app',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qr.qrPayload,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  qr.upiId,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: qr.upiId)),
                child: const Icon(Icons.copy_rounded, size: 15, color: AppColors.purpleSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
