import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.length,
    required this.onChanged,
    required this.onCompleted,
    this.hasError = false,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final bool hasError;

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Clears every box and refocuses the first one — used after a wrong-OTP
  /// error so the user can retry without leaving the screen.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    widget.onChanged('');
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handles paste of the full code into one box.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final last = digits.length.clamp(0, widget.length) - 1;
      if (last >= 0) _focusNodes[last].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    widget.onChanged(_value);
    if (_value.length == widget.length) {
      widget.onCompleted(_value);
    }
  }

  void _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      widget.onChanged(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 46,
          height: 54,
          child: GlassContainer(
            borderRadius: 12,
            borderColor: widget.hasError ? AppColors.live : AppColors.glassBorder,
            child: KeyboardListener(
              focusNode: FocusNode(skipTraversal: true),
              onKeyEvent: (e) => _onKey(i, e),
              child: TextField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: widget.length, // allows paste-into-one-box
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: AppColors.purple,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onChanged(i, v),
              ),
            ),
          ),
        );
      }),
    );
  }
}
