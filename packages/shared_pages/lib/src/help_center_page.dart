import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const AppHelpTopic({
  required this.category,
  required this.question,
  required this.answer,
}) {
  final String category;
  final String question;
  final String answer;
}

class const AppHelpCenterPage({
  super.key,
  required this.topics,
  required this.onBack,
  this.description = 'Find answers for common EasyRide questions.',
  this.onEmailSupport,
  this.onCallSupport,
}) extends StatefulWidget {
  final List<AppHelpTopic> topics;
  final VoidCallback onBack;
  final String description;
  final VoidCallback? onEmailSupport;
  final VoidCallback? onCallSupport;

  @override
  State<AppHelpCenterPage> createState() => _AppHelpCenterPageState();
}

class _AppHelpCenterPageState extends State<AppHelpCenterPage>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 220);

  final _searchController = TextEditingController();
  late final AnimationController _categoryTransitionController;
  late final Animation<double> _categoryTransitionCurve;
  String _query = '';
  String? _selectedCategory;
  double _categorySlideDirection = 0;

  @override
  void initState() {
    super.initState();
    _categoryTransitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1,
    );
    _categoryTransitionCurve = CurvedAnimation(
      parent: _categoryTransitionController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AppHelpCenterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _categoryTransitionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      {for (final topic in widget.topics) topic.category}
          .toList(growable: false);

  List<AppHelpTopic> get _visibleTopics {
    final normalizedQuery = _query.trim().toLowerCase();
    return widget.topics
        .where((topic) {
          final matchesCategory =
              _selectedCategory == null || topic.category == _selectedCategory;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              topic.question.toLowerCase().contains(normalizedQuery) ||
              topic.answer.toLowerCase().contains(normalizedQuery);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }

  void _selectCategory(String? nextCategory) {
    if (nextCategory == _selectedCategory) return;
    final allCategories = <String?>[null, ..._categories];
    final previousIndex = allCategories.indexOf(_selectedCategory);
    final nextIndex = allCategories.indexOf(nextCategory);
    setState(() {
      _categorySlideDirection = nextIndex > previousIndex ? 1.0 : -1.0;
      _selectedCategory = nextCategory;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _categoryTransitionController.value = 1;
    } else {
      unawaited(_categoryTransitionController.forward(from: 0));
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategory = null;
      _categorySlideDirection = -1;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _categoryTransitionController.value = 1;
    } else {
      unawaited(_categoryTransitionController.forward(from: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visibleTopics = _visibleTopics;

    return AppSecondaryPage(
      title: 'Help Center',
      onBack: widget.onBack,
      maxWidth: 600,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360
              ? AppLayout.pagePadding
              : AppLayout.pagePaddingWide;
          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.md,
              horizontalPadding,
              48,
            ),
            children: [
              Text(
                'How can we help?',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                widget.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                key: const ValueKey<String>('help-center-search'),
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search help topics',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          key: const ValueKey<String>(
                            'help-center-clear-search',
                          ),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          style: IconButton.styleFrom(
                            enableFeedback: false,
                            splashFactory: NoSplash.splashFactory,
                          ),
                          icon: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        onSelected: () => _selectCategory(null),
                      ),
                      for (final category in _categories) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _CategoryChip(
                          label: category,
                          isSelected: _selectedCategory == category,
                          onSelected: () => _selectCategory(category),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedBuilder(
                animation: _categoryTransitionCurve,
                builder: (context, child) {
                  final progress = _categoryTransitionCurve.value;
                  final dx = _categorySlideDirection * 12 * (1 - progress);
                  return Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    ),
                  );
                },
                child: visibleTopics.isEmpty
                    ? _EmptyHelpSearch(
                        onReset: _query.isNotEmpty || _selectedCategory != null
                            ? _clearFilters
                            : null,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            for (final topic in visibleTopics)
                              _HelpTopicRow(
                                key: ValueKey<String>(
                                  'help-topic-${topic.question}',
                                ),
                                topic: topic,
                              ),
                          ],
                        ),
                      ),
              ),
              if (widget.onEmailSupport != null ||
                  widget.onCallSupport != null) ...[
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'STILL NEED HELP?',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (widget.onEmailSupport != null)
                  _buildSupportButton(
                    context,
                    icon: LucideIcons.mail,
                    label: 'Email support',
                    onPressed: widget.onEmailSupport!,
                  ),
                if (widget.onEmailSupport != null &&
                    widget.onCallSupport != null)
                  const SizedBox(height: AppSpacing.sm + 2),
                if (widget.onCallSupport != null)
                  _buildSupportButton(
                    context,
                    icon: LucideIcons.phone,
                    label: 'Call support',
                    onPressed: widget.onCallSupport!,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSupportButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = context.colorScheme;
    return SizedBox(
      height: AppSize.controlHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return colorScheme.primary.withValues(alpha: 0.12);
                }
                return Colors.transparent;
              }),
            ),
        icon: Icon(icon, size: 17),
        label: Text(label),
      ),
    );
  }
}

class const _CategoryChip({
  required this.label,
  required this.isSelected,
  required this.onSelected,
}) extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.minimumTouchTarget),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onSelected(),
        backgroundColor: colorScheme.surfaceContainerLowest,
        selectedColor: colorScheme.primary,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isSelected
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }
}

class const _HelpTopicRow({super.key, required this.topic})
    extends StatefulWidget {
  final AppHelpTopic topic;

  @override
  State<_HelpTopicRow> createState() => _HelpTopicRowState();
}

class _HelpTopicRowState extends State<_HelpTopicRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Semantics(
        button: true,
        expanded: _isExpanded,
        label: widget.topic.question,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return Colors.transparent;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.topic.question,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: ExcludeSemantics(
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: animationDuration,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            LucideIcons.chevron_down,
                            size: 17,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: animationDuration,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: _isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm + 2,
                            right: AppSpacing.xl,
                          ),
                          child: Text(
                            widget.topic.answer,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class const _EmptyHelpSearch({this.onReset}) extends StatelessWidget {
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.search_x,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No help topics found',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try a different search or category.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              key: const ValueKey<String>('help-center-reset-filters'),
              onPressed: onReset,
              style:
                  TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.focused)) {
                        return colorScheme.primary.withValues(alpha: 0.12);
                      }
                      return Colors.transparent;
                    }),
                  ),
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}
