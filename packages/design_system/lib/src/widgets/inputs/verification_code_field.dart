import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppVerificationCodeField extends StatelessWidget {
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
  Widget build(BuildContext context) => Column(
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
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: autofocus,
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
                onSubmitted: onSubmitted,
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
                  animation: Listenable.merge([controller, focusNode]),
                  builder: (context, _) => Row(
                    children: [
                      for (var index = 0; index < 6; index++) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: errorText != null
                                    ? context.colorScheme.error
                                    : focusNode.hasFocus &&
                                          index ==
                                              controller.text.length.clamp(0, 5)
                                    ? context.colorScheme.primary
                                    : context.colorScheme.outlineVariant,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                index < controller.text.length
                                    ? controller.text[index]
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
          errorText!,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colorScheme.error,
          ),
        ),
      ],
    ],
  );
}
