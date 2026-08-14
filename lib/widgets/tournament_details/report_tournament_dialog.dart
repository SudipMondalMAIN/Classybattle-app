import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/moderation_service.dart';
import '../../theme/app_theme.dart';

/// Report dialog for a tournament — reportable from the moment it goes
/// live and for its whole lifetime after that (enforced backend-side;
/// this dialog just surfaces whatever message comes back if it's too
/// early).
Future<void> showReportTournamentDialog(
  BuildContext context, {
  required String tournamentId,
}) {
  return showDialog(
    context: context,
    builder: (_) => _ReportTournamentDialog(tournamentId: tournamentId),
  );
}

class _ReportTournamentDialog extends StatefulWidget {
  const _ReportTournamentDialog({required this.tournamentId});
  final String tournamentId;

  @override
  State<_ReportTournamentDialog> createState() =>
      _ReportTournamentDialogState();
}

class _ReportTournamentDialogState extends State<_ReportTournamentDialog> {
  ReportReason _reason = ReportReason.cheating;
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await moderationService.submitReport(
        targetType: ReportTargetType.tournament,
        targetId: widget.tournamentId,
        reason: _reason,
        description: _descriptionController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. Our team will review it.'),
          ),
        );
      }
    } on SubmitReportException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Report Tournament',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<ReportReason>(
              value: _reason,
              dropdownColor: AppColors.background,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              items: [
                for (final r in ReportReason.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _reason = v);
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Details (optional)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 2000,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'What happened?',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.live, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.live),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
