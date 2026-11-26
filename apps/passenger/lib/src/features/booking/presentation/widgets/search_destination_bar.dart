import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';

class SearchDestinationBar extends StatelessWidget {
  const SearchDestinationBar({
    super.key,
    required this.expandProgress,
    required this.mapPinFadeAnimation,
    required this.collapsedControlsFadeAnimation,
    required this.searchController,
    required this.focusNode,
    required this.onBackTap,
    required this.onOpenMapPin,
    required this.onClearSearch,
  });

  final double expandProgress;
  final Animation<double> mapPinFadeAnimation;
  final Animation<double> collapsedControlsFadeAnimation;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final VoidCallback onBackTap;
  final VoidCallback onOpenMapPin;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final t = expandProgress;
    final colors = context.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: (1.0 - t) * 56.0),
                  child: Hero(
                    tag: 'search_bar_field',
                    child: Material(
                      color: colors.surface.withValues(alpha: 0),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              key: const ValueKey('search-destination-back'),
                              onTap: onBackTap,
                              child: SizedBox(
                                width: AppSize.minimumTouchTarget,
                                height: AppSize.minimumTouchTarget,
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                    child: Icon(
                                      t > 0.4
                                          ? LucideIcons.arrow_left
                                          : LucideIcons.search,
                                      key: ValueKey(t > 0.4),
                                      color: colors.onSurface,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                focusNode: focusNode,
                                autofocus: false,
                                style: context.textStyles.bodyLarge?.copyWith(
                                  fontSize: 15,
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search destination',
                                  hintStyle: context.textStyles.bodyLarge
                                      ?.copyWith(
                                        fontSize: 15,
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w400,
                                      ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: onClearSearch,
                                child: SizedBox(
                                  width: AppSize.minimumTouchTarget,
                                  height: AppSize.minimumTouchTarget,
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.x,
                                      size: 18,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            if (t >= 0.4)
                              FadeTransition(
                                opacity: mapPinFadeAnimation,
                                child: Transform.scale(
                                  scale: ((t - 0.4) / 0.6).clamp(0.0, 1.0),
                                  child: GestureDetector(
                                    key: const ValueKey(
                                      'search-destination-map-pin',
                                    ),
                                    onTap: onOpenMapPin,
                                    child: Material(
                                      color: colors.surface.withValues(
                                        alpha: 0,
                                      ),
                                      child: SizedBox(
                                        width: AppSize.minimumTouchTarget,
                                        height: AppSize.minimumTouchTarget,
                                        child: Center(
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: colors
                                                  .surfaceContainerHighest,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              LucideIcons.map_pin,
                                              color: colors.onSurface,
                                              size: 18,
                                            ),
                                          ),
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
                  ),
                ),
              ),
              if (t < 0.4)
                Positioned(
                  left: 0,
                  top: 3,
                  child: FadeTransition(
                    opacity: collapsedControlsFadeAnimation,
                    child: Transform.scale(
                      scale: (1.0 - t * 0.5).clamp(0.0, 1.0),
                      child: AppMapBackButton(onPressed: onBackTap),
                    ),
                  ),
                ),
              if (t < 0.4)
                Positioned(
                  right: 0,
                  top: 3,
                  child: FadeTransition(
                    opacity: collapsedControlsFadeAnimation,
                    child: Transform.scale(
                      scale: (1.0 - t * 0.5).clamp(0.0, 1.0),
                      child: GestureDetector(
                        key: const ValueKey('search-destination-map-pin'),
                        onTap: onOpenMapPin,
                        child: SizedBox(
                          width: AppSize.minimumTouchTarget,
                          height: AppSize.minimumTouchTarget,
                          child: Hero(
                            tag: BookingRoutes.mapPinHeroTag,
                            child: FittedBox(
                              child: Material(
                                color: colors.surface.withValues(alpha: 0),
                                child: Container(
                                  width: AppSize.minimumTouchTarget,
                                  height: AppSize.minimumTouchTarget,
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.outlineVariant,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.onSurface.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.map_pin,
                                      color: colors.onSurface,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
