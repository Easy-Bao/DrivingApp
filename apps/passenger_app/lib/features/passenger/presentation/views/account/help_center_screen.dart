import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/shared/widgets/custom_toast.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final Set<int> _expandedItems = {};

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I book a ride?',
      'a':
          "Tap 'Enter destination' on the home screen, search for your destination or pin it on the map, then tap 'Book Ride' to confirm.",
      'cat': 'Rides',
    },
    {
      'q': 'How do I cancel a ride?',
      'a':
          "Go to Activity → find your upcoming ride → tap 'Track Driver' → then tap 'Cancel Trip' at the bottom.",
      'cat': 'Rides',
    },
    {
      'q': 'What is Share-Bao?',
      'a':
          "Share-Bao lets you share a ride with others heading the same direction. It's a cheaper alternative to solo rides!",
      'cat': 'Rides',
    },
    {
      'q': 'How do I update my payment method?',
      'a':
          'Currently, BaoRide supports cash payments. Digital payment options will be available soon.',
      'cat': 'Payments',
    },
    {
      'q': 'How do I get a receipt?',
      'a':
          'After your ride is completed, go to Activity → View Details. Your receipt with fare breakdown is shown there.',
      'cat': 'Payments',
    },
    {
      'q': 'How do I change my phone number?',
      'a':
          'Go to Account → Profile Info → tap Edit → update your phone number → tap Save Changes.',
      'cat': 'Account',
    },
    {
      'q': 'How do I enable biometric login?',
      'a':
          "Go to Account → Security → toggle on 'Biometric Login'. Make sure your device supports fingerprint or Face ID.",
      'cat': 'Account',
    },
    {
      'q': 'Is my data secure?',
      'a':
          'Yes! We use industry-standard encryption to protect your personal information and ride data.',
      'cat': 'General',
    },
    {
      'q': 'How do I contact support?',
      'a':
          'You can reach us via email at support@baoride.com or call +63 912 345 6789 during business hours.',
      'cat': 'General',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    var list = _faqs;
    if (_selectedCategory != 'All') {
      list = list.where((faqItem) => f['cat'] == _selectedCategory).toList();
    }
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (faqItem) =>
                f['q']!.toLowerCase().contains(q) ||
                f['a']!.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  final List<String> _categories = [
    'All',
    'Rides',
    'Payments',
    'Account',
    'General',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.neutralColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSide),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  hintStyle: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  icon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final sel = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryColor : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primaryColor
                            : AppTheme.borderSide,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length + 1, // +1 for contact card
                    itemBuilder: (ctx, i) {
                      if (i == filtered.length) return _buildContactCard();
                      final faq = filtered[i];
                      final idx = _faqs.indexOf(faq);
                      final expanded = _expandedItems.contains(idx);
                      return _buildFaqItem(faq, idx, expanded);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq, int idx, bool expanded) {
    return GestureDetector(
      onTap: () => setState(() {
        if (expanded) {
          _expandedItems.remove(idx);
        } else {
          _expandedItems.add(idx);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: expanded ? AppTheme.neutralColor : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: expanded
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : AppTheme.borderSide,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq['q']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevron_down,
                    size: 16,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        faq['a']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Still need help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Our support team is available 24/7',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _contactBtn(LucideIcons.mail, 'Email Us')),
              const SizedBox(width: 12),
              Expanded(child: _contactBtn(LucideIcons.phone, 'Call Us')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactBtn(IconData icon, String text) {
    return GestureDetector(
      onTap: () => CustomToast.show(context, '$text — coming soon!'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
