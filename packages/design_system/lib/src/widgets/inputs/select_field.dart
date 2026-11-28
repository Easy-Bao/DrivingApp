import 'dart:async';

import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:design_system/src/widgets/layout/bottom_sheet_container.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const AppSelectOption<T>({required this.value, required this.label}) {
  final T value;
  final String label;
}

class AppSelectField<T> extends StatefulWidget {
  const AppSelectField({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.decoration = const InputDecoration(),
    this.menuTitle,
    this.style,
  }) : _anchored = false;

  const AppSelectField.anchored({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.decoration = const InputDecoration(),
    this.menuTitle,
    this.style,
  }) : _anchored = true;

  final bool _anchored;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final String? menuTitle;
  final TextStyle? style;

  @override
  State<AppSelectField<T>> createState() => _AppSelectFieldState<T>();
}

class _AppSelectFieldState<T> extends State<AppSelectField<T>> {
  bool _isMenuOpen = false;

  AppSelectOption<T>? get _selectedOption {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  Future<void> _openMenu() async {
    if (widget.onChanged == null || _isMenuOpen) return;

    setState(() => _isMenuOpen = true);
    final selectedValue = widget._anchored
        ? await _showAnchoredMenu()
        : await showModalBottomSheet<T>(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            showDragHandle: false,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _AppSelectMenu<T>(
              title:
                  widget.menuTitle ??
                  widget.decoration.labelText ??
                  widget.decoration.hintText ??
                  'Select an option',
              options: widget.options,
              selectedValue: widget.value,
            ),
          );
    if (!mounted) return;

    setState(() => _isMenuOpen = false);
    if (selectedValue != null) widget.onChanged?.call(selectedValue);
  }

  Future<T?> _showAnchoredMenu() {
    final renderObject = context.findRenderObject();
    final overlayRenderObject = Navigator.of(context).overlay?.context
        .findRenderObject();
    if (renderObject is! RenderBox || overlayRenderObject is! RenderBox) {
      return Future<T?>.value();
    }
    final box = renderObject;
    final overlay = overlayRenderObject;
    final origin = box.localToGlobal(
      Offset(0, box.size.height + 4),
      ancestor: overlay,
    );
    return showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        origin & Size(box.size.width, 0),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
        maxHeight: 300,
      ),
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      items: [
        for (final option in widget.options)
          PopupMenuItem<T>(
            value: option.value,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.label,
                    style:
                        (widget.style ?? Theme.of(context).textTheme.bodyLarge)
                            ?.copyWith(
                              fontWeight: option.value == widget.value
                                  ? FontWeight.w700
                                  : null,
                            ),
                  ),
                ),
                if (option.value == widget.value) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      unawaited(_openMenu());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _selectedOption;
    final enabled = widget.onChanged != null;
    final decoration = widget.decoration.copyWith(
      enabled: enabled,
      suffixIcon:
          widget.decoration.suffixIcon ??
          Icon(_isMenuOpen ? LucideIcons.chevron_up : LucideIcons.chevron_down),
    );
    final border = decoration.border;
    final borderRadius = border is OutlineInputBorder
        ? border.borderRadius
        : BorderRadius.circular(AppRadius.lg);

    return Semantics(
      button: true,
      enabled: enabled,
      label: decoration.labelText ?? decoration.hintText ?? 'Select an option',
      value: selectedOption?.label ?? decoration.hintText ?? 'No selection',
      onTap: enabled ? _openMenu : null,
      child: Focus(
        canRequestFocus: enabled,
        onKeyEvent: enabled ? _handleKeyEvent : null,
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: enabled ? _openMenu : null,
                canRequestFocus: false,
                borderRadius: borderRadius,
                child: InputDecorator(
                  decoration: decoration,
                  isEmpty: selectedOption == null,
                  isFocused: _isMenuOpen || hasFocus,
                  child: selectedOption == null
                      ? null
                      : Text(
                          selectedOption.label,
                          style:
                              widget.style ??
                              Theme.of(context).textTheme.bodyLarge,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppSelectMenu<T> extends StatelessWidget {
  const _AppSelectMenu({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<AppSelectOption<T>> options;
  final T? selectedValue;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm + 2,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final option in options) ...[
              _AppSelectOptionTile<T>(
                option: option,
                selected: option.value == selectedValue,
              ),
              if (option != options.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppSelectOptionTile<T> extends StatelessWidget {
  const _AppSelectOptionTile({required this.option, required this.selected});

  final AppSelectOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimaryContainer : colors.onSurface;
    final background = selected
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: Material(
        color: background,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(option.value),
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.controlHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight: selected ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      LucideIcons.check,
                      size: 20,
                      color: colors.onPrimaryContainer,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
