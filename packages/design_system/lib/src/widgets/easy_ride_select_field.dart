import 'dart:async';

import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const EasyRideSelectOption<T>({
  required this.value,
  required this.label,
}) {
  final T value;
  final String label;
}

class const EasyRideSelectField<T>({
  super.key,
  required this.options,
  required this.onChanged,
  this.value,
  this.decoration = const InputDecoration(),
  this.menuTitle,
  this.style,
}) extends StatefulWidget {
  final T? value;
  final List<EasyRideSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final String? menuTitle;
  final TextStyle? style;

  @override
  State<EasyRideSelectField<T>> createState() => _EasyRideSelectFieldState<T>();
}

class _EasyRideSelectFieldState<T> extends State<EasyRideSelectField<T>> {
  bool _isMenuOpen = false;

  EasyRideSelectOption<T>? get _selectedOption {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  Future<void> _openMenu() async {
    if (widget.onChanged == null) return;

    setState(() => _isMenuOpen = true);
    final selectedValue = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EasyRideSelectMenu<T>(
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
    if (selectedValue != null) widget.onChanged!(selectedValue);
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
          widget.decoration.suffixIcon ?? const Icon(LucideIcons.chevron_down),
    );
    final borderRadius = decoration.border is OutlineInputBorder
        ? (decoration.border! as OutlineInputBorder).borderRadius
        : BorderRadius.circular(EasyRideRadius.lg);

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
                canRequestFocus: enabled,
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

class _EasyRideSelectMenu<T> extends StatelessWidget {
  const _EasyRideSelectMenu({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<EasyRideSelectOption<T>> options;
  final T? selectedValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(EasyRideRadius.sheet),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              EasyRideSpacing.lg,
              EasyRideSpacing.lg,
              EasyRideSpacing.lg,
              EasyRideSpacing.md,
            ),
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: EasyRideSpacing.md),
              for (final option in options) ...[
                _EasyRideSelectOptionTile<T>(
                  option: option,
                  selected: option.value == selectedValue,
                ),
                if (option != options.last)
                  const SizedBox(height: EasyRideSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EasyRideSelectOptionTile<T> extends StatelessWidget {
  const _EasyRideSelectOptionTile({
    required this.option,
    required this.selected,
  });

  final EasyRideSelectOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimaryContainer : colors.onSurface;
    final background = selected
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final borderRadius = BorderRadius.circular(EasyRideRadius.lg);

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
            constraints: const BoxConstraints(
              minHeight: EasyRideSize.controlHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EasyRideSpacing.lg,
                vertical: EasyRideSpacing.sm,
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
