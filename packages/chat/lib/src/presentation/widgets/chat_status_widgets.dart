import 'package:chat/src/presentation/bloc/chat_state.dart';
import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

class const ChatConnectionErrorBanner({
  super.key,
  required this.message,
  required this.onRetry,
}) extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: AppErrorBanner(message: message, onRetry: onRetry),
    );
  }
}

class const ChatEmptyState({
  super.key,
  required this.state,
  required this.onRetry,
}) extends StatelessWidget {
  final ChatState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    if (state.isConnecting || state.isLoadingHistory) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.onSurface,
        ),
      );
    }
    if (!state.isAccessDenied &&
        state.errorMessage != null &&
        !AppNetworkStatusScope.isUnavailableOf(context)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: onRetry,
                  style:
                      OutlinedButton.styleFrom(
                        backgroundColor: colors.surfaceContainerLowest,
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: colors.outlineVariant),
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        minimumSize: const Size(0, AppSize.minimumTouchTarget),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ).copyWith(
                        overlayColor: AppQuietInteraction.focusOverlay(
                          colors.primary,
                        ),
                      ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Center(
      child: Text(
        'No messages yet',
        style: context.textStyles.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
