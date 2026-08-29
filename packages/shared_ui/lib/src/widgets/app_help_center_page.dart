import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/src/theme/easy_ride_theme_context.dart';

class AppHelpTopic {
  const AppHelpTopic({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;
}

/// A searchable, role-configured help center without placeholder actions.
class AppHelpCenterPage extends StatefulWidget {
  const AppHelpCenterPage({
    super.key,
    required this.topics,
    required this.onBack,
    this.description = 'Find answers for common BaoRide questions.',
    this.onEmailSupport,
    this.onCallSupport,
  });

  final List<AppHelpTopic> topics;
  final VoidCallback onBack;
  final String description;
  final VoidCallback? onEmailSupport;
  final VoidCallback? onCallSupport;

  @override
  State<AppHelpCenterPage> createState() => _AppHelpCenterPageState();
}

class _AppHelpCenterPageState extends State<AppHelpCenterPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories => {
    for (final topic in widget.topics) topic.category,
  }.toList(growable: false);

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

  @override
  Widget build(BuildContext context) {
    final visibleTopics = _visibleTopics;
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: widget.onBack,
          icon: const Icon(LucideIcons.arrow_left),
        ),
        title: const Text('Help Center'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 48),
            children: [
              Text(
                'How can we help?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey<String>('help-center-search'),
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search help topics',
                  prefixIcon: Icon(LucideIcons.search),
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategory == null,
                      onSelected: () =>
                          setState(() => _selectedCategory = null),
                    ),
                    for (final category in _categories) ...[
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: category,
                        isSelected: _selectedCategory == category,
                        onSelected: () =>
                            setState(() => _selectedCategory = category),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (visibleTopics.isEmpty)
                const _EmptyHelpSearch()
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: context.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final topic in visibleTopics)
                        _HelpTopicRow(topic: topic),
                    ],
                  ),
                ),
              if (widget.onEmailSupport != null ||
                  widget.onCallSupport != null) ...[
                const SizedBox(height: 30),
                Text(
                  'Still need help?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (widget.onEmailSupport != null)
                  OutlinedButton.icon(
                    onPressed: widget.onEmailSupport,
                    icon: const Icon(LucideIcons.mail),
                    label: const Text('Email support'),
                  ),
                if (widget.onEmailSupport != null &&
                    widget.onCallSupport != null)
                  const SizedBox(height: 10),
                if (widget.onCallSupport != null)
                  OutlinedButton.icon(
                    onPressed: widget.onCallSupport,
                    icon: const Icon(LucideIcons.phone),
                    label: const Text('Call support'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _HelpTopicRow extends StatelessWidget {
  const _HelpTopicRow({required this.topic});

  final AppHelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: ValueKey<String>('help-topic-${topic.question}'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(2, 0, 20, 18),
      shape: Border(
        bottom: BorderSide(color: context.colorScheme.outlineVariant),
      ),
      collapsedShape: Border(
        bottom: BorderSide(color: context.colorScheme.outlineVariant),
      ),
      title: Text(topic.question),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            topic.answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHelpSearch extends StatelessWidget {
  const _EmptyHelpSearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(
            LucideIcons.search_x,
            size: 34,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No help topics found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Try a different search or category.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
