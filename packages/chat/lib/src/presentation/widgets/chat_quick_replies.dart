import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

class const ChatQuickReplies({
  super.key,
  required this.replies,
  required this.onSelected,
}) extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();
    final colors = context.colorScheme;
    return SizedBox(
      height: AppSize.minimumTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Semantics(
            button: true,
            label: 'Send quick reply $reply',
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: AppQuietInteraction.focusOverlay(
                    colors.primary,
                  ),
                  onTap: () => onSelected(reply),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      reply,
                      style: context.textStyles.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
