import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/presentation/bloc/document_upload/document_upload_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class const DocumentUploadPage({super.key, this.pickPhoto, this.onBack})
    extends StatefulWidget {
  final Future<XFile?> Function()? pickPhoto;
  final VoidCallback? onBack;

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  DriverDocumentType _type = DriverDocumentType.driverLicense;
  XFile? _draft;
  Uint8List? _draftBytes;
  String? _draftError;
  bool _isPickingPhoto = false;

  Future<void> _choosePhoto() async {
    if (_isPickingPhoto) return;
    _isPickingPhoto = true;
    try {
      final pickPhoto = widget.pickPhoto;
      final picked = pickPhoto == null
          ? await ImagePicker().pickImage(
              source: ImageSource.camera,
              maxWidth: 1800,
              imageQuality: 90,
            )
          : await pickPhoto();
      if (!mounted || picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _draft = picked;
        _draftBytes = bytes;
        _draftError = null;
      });
      BlocProvider.of<DocumentUploadCubit>(context).reset();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _draft = null;
        _draftBytes = null;
        _draftError = 'The selected photo could not be loaded. Choose another.';
      });
    } finally {
      _isPickingPhoto = false;
    }
  }

  Future<void> _submit() async {
    final draft = _draft;
    final bytes = _draftBytes;
    if (draft == null || bytes == null) return;
    final contentType = _contentType(draft);
    if (contentType == null) {
      setState(() => _draftError = 'Choose a JPEG or PNG photo.');
      return;
    }
    await BlocProvider.of<DocumentUploadCubit>(context)
        .submit(type: _type, bytes: bytes, contentType: contentType);
  }

  String? _contentType(XFile file) {
    final declared = file.mimeType?.toLowerCase();
    if (declared == 'image/jpeg' || declared == 'image/png') return declared;
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return BlocListener<DocumentUploadCubit, DocumentUploadState>(
      listener: (context, state) {
        if (state.status == DocumentUploadStatus.succeeded) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Document submitted for review.')),
            );
          setState(() {
            _draft = null;
            _draftBytes = null;
          });
        } else if (state.status == DocumentUploadStatus.failed) {
          setState(() => _draftError = state.message);
        }
      },
      child: AppSecondaryPage(
        title: 'Driver Documents',
        onBack: widget.onBack ?? () => context.pop(),
        maxWidth: 560,
        child: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
          builder: (context, state) => LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? AppLayout.pagePadding
                  : AppLayout.pagePaddingWide;
              return ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.sm,
                  horizontalPadding,
                  AppSpacing.xxxl,
                ),
                children: [
                  Text(
                    'Submit a clear photo for review',
                    style: textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your photo stays on this screen until you confirm the upload.',
                    style: textStyles.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DocumentTypeSelector(
                    selected: _type,
                    enabled: !state.isUploading,
                    onSelected: (next) => setState(() => _type = next),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPreview(context, isUploading: state.isUploading),
                  if (_draftError case final draftError?) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: ExcludeSemantics(
                              child: Icon(
                                LucideIcons.circle_alert,
                                size: 15,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              draftError,
                              key: const ValueKey(
                                'driver-document-upload-error',
                              ),
                              style: textStyles.bodySmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: AppSize.controlHeight,
                    child: OutlinedButton.icon(
                      key: const ValueKey('driver-document-choose-photo'),
                      onPressed: state.isUploading ? null : _choosePhoto,
                      style:
                          OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            backgroundColor: Colors.transparent,
                            side: BorderSide(color: colorScheme.outlineVariant),
                            enableFeedback: false,
                            splashFactory: NoSplash.splashFactory,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ).copyWith(
                            overlayColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.focused)) {
                                return colorScheme.primary.withValues(
                                  alpha: 0.12,
                                );
                              }
                              return Colors.transparent;
                            }),
                          ),
                      icon: const Icon(LucideIcons.camera, size: 17),
                      label: Text(
                        _draft == null ? 'Take a photo' : 'Retake photo',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  SizedBox(
                    height: AppSize.controlHeight,
                    child: FilledButton(
                      key: const ValueKey('driver-document-submit'),
                      onPressed: _draft == null || state.isUploading
                          ? null
                          : _submit,
                      style:
                          FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            enableFeedback: false,
                            splashFactory: NoSplash.splashFactory,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ).copyWith(
                            overlayColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.focused)) {
                                return colorScheme.onPrimary.withValues(
                                  alpha: 0.16,
                                );
                              }
                              return Colors.transparent;
                            }),
                          ),
                      child: state.isUploading
                          ? SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Submit document'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, {required bool isUploading}) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final draft = _draft;
    final bytes = _draftBytes;

    if (draft == null || bytes == null) {
      return Semantics(
        button: true,
        label: 'No photo selected. Take a photo',
        child: InkWell(
          onTap: isUploading ? null : _choosePhoto,
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
          child: Container(
            key: const ValueKey('driver-document-empty-preview'),
            constraints: const BoxConstraints(minHeight: 184),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.camera,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No photo selected',
                  style: textStyles.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Use good lighting so all edges and text stay legible.',
                  textAlign: TextAlign.center,
                  style: textStyles.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('driver-document-photo-preview'),
      height: 184,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        bytes,
        height: 184,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            'Preview unavailable',
            style: textStyles.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class const _DocumentTypeSelector({
  required this.selected,
  required this.enabled,
  required this.onSelected,
}) extends StatelessWidget {
  final DriverDocumentType selected;
  final bool enabled;
  final ValueChanged<DriverDocumentType> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 290 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final options = [
            _DocumentTypeOption(
              key: const ValueKey<String>('driver-document-type-license'),
              icon: LucideIcons.id_card,
              label: "Driver's license",
              isSelected: selected == DriverDocumentType.driverLicense,
              duration: animationDuration,
              onTap: enabled
                  ? () => onSelected(DriverDocumentType.driverLicense)
                  : null,
            ),
            _DocumentTypeOption(
              key: const ValueKey<String>('driver-document-type-registration'),
              icon: LucideIcons.file_text,
              label: 'Vehicle registration',
              isSelected: selected == DriverDocumentType.vehicleRegistration,
              duration: animationDuration,
              onTap: enabled
                  ? () => onSelected(DriverDocumentType.vehicleRegistration)
                  : null,
            ),
          ];
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                options[0],
                const SizedBox(height: AppSpacing.xs),
                options[1],
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: options[0]),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: options[1]),
            ],
          );
        },
      ),
    );
  }
}

class const _DocumentTypeOption({
  super.key,
  required this.icon,
  required this.label,
  required this.isSelected,
  required this.duration,
  required this.onTap,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final foreground = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 16, color: foreground)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
