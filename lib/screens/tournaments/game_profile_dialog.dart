import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../core/api_exception.dart';
import '../auth/auth_widgets.dart';

/// Shows a popup asking for the fields defined in [game.profileSchema]
/// (e.g. Free Fire -> nickname + UID). Used the first time a user joins
/// a tournament for a game they don't have a saved profile for yet.
/// Returns the saved [UserGameProfile], or null if the user cancelled.
Future<UserGameProfile?> showGameProfileDialog(
  BuildContext context, {
  required Game game,
  UserGameProfile? existing, // pass to edit instead of create
}) {
  return showDialog<UserGameProfile>(
    context: context,
    barrierDismissible: false,
    builder: (_) => GameProfileDialog(game: game, existing: existing),
  );
}

class GameProfileDialog extends StatefulWidget {
  final Game game;
  final UserGameProfile? existing;

  const GameProfileDialog({super.key, required this.game, this.existing});

  @override
  State<GameProfileDialog> createState() => _GameProfileDialogState();
}

class _GameProfileDialogState extends State<GameProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = GameService();
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.game.profileSchema) {
      _controllers[field.key] =
          TextEditingController(text: widget.existing?.data[field.key]?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {for (final e in _controllers.entries) e.key: e.value.text.trim()};
    try {
      final profile = widget.existing == null
          ? await _service.createProfile(gameId: widget.game.id, data: data)
          : await _service.updateProfile(gameId: widget.game.id, data: data);
      if (mounted) Navigator.of(context).pop(profile);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAuthSnack(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit ${widget.game.name} Profile' : 'Add ${widget.game.name} Profile',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Save once and use it for every tournament in this game',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              for (final field in widget.game.profileSchema) ...[
                AuthTextField(
                  controller: _controllers[field.key]!,
                  label: field.label,
                  keyboardType:
                      field.type == 'number' ? TextInputType.number : TextInputType.text,
                  validator: field.required
                      ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null
                      : null,
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _saving
                        ? const Center(
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.purple),
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
    );
  }
}
