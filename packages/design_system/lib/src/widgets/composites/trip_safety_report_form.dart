import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const SafetyReportReason({required this.value, required this.label}) {
  final String value;
  final String label;
}

Future<bool> showTripSafetyReportForm(
  BuildContext context, {
  required String title,
  required List<SafetyReportReason> reasons,
  required Future<String?> Function(String category, String description)
  onSubmit,
  Widget? tripSummary,
}) async {
  final submitted =
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => TripSafetyReportForm(
          title: title,
          reasons: reasons,
          tripSummary: tripSummary,
          onSubmit: onSubmit,
        ),
      ) ??
      false;
  if (submitted && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Report submitted.')));
  }
  return submitted;
}

class TripSafetyReportForm extends StatefulWidget {
  const TripSafetyReportForm({
    super.key,
    required this.title,
    required this.reasons,
    required this.onSubmit,
    this.tripSummary,
  });
  final String title;
  final List<SafetyReportReason> reasons;
  final Widget? tripSummary;

  /// Returns a user-facing failure message, or null after a successful submission.
  final Future<String?> Function(String category, String description) onSubmit;

  @override
  State<TripSafetyReportForm> createState() => _TripSafetyReportFormState();
}

class _TripSafetyReportFormState extends State<TripSafetyReportForm> {
  final _descriptionController = TextEditingController();
  String? _category;
  String? _errorMessage;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isSubmitting &&
      _category != null &&
      _descriptionController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final category = _category;
    final description = _descriptionController.text.trim();
    if (_isSubmitting) return;
    if (category == null || description.isEmpty) {
      setState(
        () => _errorMessage = 'Choose a reason and describe what happened.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    String? error;
    try {
      error = await widget.onSubmit(category, description);
    } catch (_) {
      error = 'Unable to submit your report. Please try again.';
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xs,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: context.textStyles.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tell us what happened on this trip.',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (widget.tripSummary != null) ...[
                      widget.tripSummary!,
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        'What happened?',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 0,
                      children: [
                        for (final option in widget.reasons)
                          ChoiceChip(
                            key: ValueKey('report-reason-${option.value}'),
                            label: Text(option.label),
                            selected: _category == option.value,
                            onSelected: _isSubmitting
                                ? null
                                : (_) => setState(() {
                                    _category = option.value;
                                    _errorMessage = null;
                                  }),
                            selectedColor: colors.primary,
                            backgroundColor: colors.surface,
                            checkmarkColor: colors.onPrimary,
                            labelStyle: context.textStyles.labelLarge?.copyWith(
                              color: _category == option.value
                                  ? colors.onPrimary
                                  : colors.onSurface,
                            ),
                            side: BorderSide(
                              color: _category == option.value
                                  ? colors.primary
                                  : colors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            visualDensity: VisualDensity.standard,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      key: const ValueKey('report-details'),
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 2000,
                      enabled: !_isSubmitting,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() => _errorMessage = null),
                      decoration: const InputDecoration(
                        labelText: 'Details (required)',
                        hintText:
                            'Describe what happened, including where and when.',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_errorMessage != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _errorMessage!,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppSize.controlHeight,
                          ),
                          textStyle: context.textStyles.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        onPressed: _canSubmit ? _submit : null,
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Flexible(child: Text('Submitting…')),
                                ],
                              )
                            : const Text('Submit report'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
