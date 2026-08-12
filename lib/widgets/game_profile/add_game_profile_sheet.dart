import 'package:flutter/material.dart';
import '../../models/game_model.dart';
import '../../models/game_profile_model.dart';
import '../../services/game_profile_service.dart';
import '../../services/home_service.dart' show UnauthenticatedException;
import '../../theme/app_theme.dart';

/// Bottom sheet collecting the user's in-game identity (nickname/UID
/// etc, shape driven by [game.profileSchema]) and saving it via
/// POST /games/profiles (create) or PATCH /games/{id}/profile (edit,
/// when [existingProfile] is passed). Pops `true` on success so the
/// caller can refresh.
class AddGameProfileSheet extends StatefulWidget {
  const AddGameProfileSheet({
    super.key,
    required this.game,
    this.existingProfile,
  });

  final GameModel game;
  final GameProfileModel? existingProfile;

  static Future<bool?> show(
    BuildContext context,
    GameModel game, {
    GameProfileModel? existingProfile,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGameProfileSheet(
        game: game,
        existingProfile: existingProfile,
      ),
    );
  }

  @override
  State<AddGameProfileSheet> createState() => _AddGameProfileSheetState();
}

class _AddGameProfileSheetState extends State<AddGameProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existingProfile != null;

  @override
  void initState() {
    super.initState();
    for (final field in widget.game.profileSchema) {
      final existingValue = widget.existingProfile?.data[field.key];
      _controllers[field.key] = TextEditingController(
        text: existingValue?.toString() ?? '',
      );
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
    // No fields defined for this game -- nothing to collect, just
    // create an empty profile row so the join can proceed.
    final hasFields = widget.game.profileSchema.isNotEmpty;
    if (hasFields && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = {
        for (final e in _controllers.entries) e.key: e.value.text.trim(),
      };
      if (_isEdit) {
        await gameProfileService.updateGameProfile(widget.game.id, data);
      } else {
        await gameProfileService.createGameProfile(widget.game.id, data);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on UnauthenticatedException {
      if (!mounted) return;
      setState(() {
        _error = 'Please log in to save your game profile.';
        _saving = false;
      });
    } on GameProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.game.profileSchema;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEdit
                    ? 'Edit ${widget.game.name} Profile'
                    : 'Add ${widget.game.name} Profile',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEdit
                    ? 'Update your saved in-game details for this game.'
                    : 'We need your in-game details before you can join a tournament for this game.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              if (fields.isEmpty)
                Text(
                  _isEdit
                      ? 'No details needed for this game.'
                      : 'No details needed for this game -- tap Save to continue.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                )
              else
                ...fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: _controllers[field.key],
                      keyboardType: field.type == 'number'
                          ? TextInputType.number
                          : TextInputType.text,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: field.required
                            ? '${field.label} *'
                            : field.label,
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.glassFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: field.required
                          ? (v) => (v == null || v.trim().isEmpty)
                              ? '${field.label} is required'
                              : null
                          : null,
                    ),
                  ),
                ),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.live, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.purpleButton,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Save Changes' : 'Save & Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
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
