import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class AppVerificationCodeField extends StatefulWidget {
  const AppVerificationCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool autofocus;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppVerificationCodeField> createState() =>
      _AppVerificationCodeFieldState();
}

class _AppVerificationCodeFieldState extends State<AppVerificationCodeField> {
  late Listenable _inputListenable;

  @override
  void initState() {
    super.initState();
    _inputListenable = Listenable.merge([widget.controller, widget.focusNode]);
  }

  @override
  void didUpdateWidget(covariant AppVerificationCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.focusNode != oldWidget.focusNode) {
      _inputListenable = Listenable.merge([
        widget.controller,
        widget.focusNode,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorText = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Semantics(
                label: 'Verification code',
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  showCursor: false,
                  onSubmitted: widget.onSubmitted,
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _inputListenable,
                    builder: (context, _) => Row(
                      children: [
                        for (var index = 0; index < 6; index++) ...[
                          if (index > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: context.colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(
                                  color: errorText != null
                                      ? context.colorScheme.error
                                      : widget.focusNode.hasFocus &&
                                            index ==
                                                widget.controller.text.length
                                                    .clamp(0, 5)
                                      ? context.colorScheme.primary
                                      : context.colorScheme.outlineVariant,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  index < widget.controller.text.length
                                      ? widget.controller.text[index]
                                      : '',
                                  style: context.textStyles.titleLarge,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
