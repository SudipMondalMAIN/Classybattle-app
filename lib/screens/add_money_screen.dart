import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/mock_data.dart';
import '../widgets/common.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  int _selectedAmount = 100;
  int _paymentMethod = 0;

  final _methods = [
    (Icons.qr_code_2_rounded, 'UPI', 'Instant Payment'),
    (Icons.credit_card_rounded, 'Credit / Debit Card', 'Visa, MasterCard, Rupay'),
    (Icons.account_balance_rounded, 'Net Banking', 'All Major Banks'),
    (Icons.account_balance_wallet_rounded, 'Wallets', 'Paytm, PhonePe, Amazon Pay'),
  ];

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
                  const Text('Add Money',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                children: [
                  const Text('Select Amount',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...MockData.addMoneyOptions.map((amt) {
                        final selected = amt == _selectedAmount;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAmount = amt),
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
                        onTap: () => setState(() => _selectedAmount = 0),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 36 - 20) / 4,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Text('Other',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text('Select Payment Method',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...List.generate(_methods.length, (i) {
                    final m = _methods[i];
                    final selected = i == _paymentMethod;
                    return GestureDetector(
                      onTap: () => setState(() => _paymentMethod = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: selected ? AppColors.purple : AppColors.cardBorder, width: selected ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(m.$1, color: AppColors.purple, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text(m.$3, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            Icon(
                              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: selected ? AppColors.purple : AppColors.textMuted,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: GradientButton(
          label: 'ADD ₹${_selectedAmount == 0 ? '--' : _selectedAmount}',
          height: 52,
          width: double.infinity,
          fontSize: 15,
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Money added successfully!'), backgroundColor: AppColors.success),
            );
          },
        ),
      ),
    );
  }
}
