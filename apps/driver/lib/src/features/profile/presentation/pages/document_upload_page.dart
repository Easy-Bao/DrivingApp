import 'dart:async';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/presentation/bloc/document_upload/document_upload_cubit.dart';
import 'package:driver/src/features/profile/presentation/widgets/document_upload_widgets.dart';
import 'package:flutter/services.dart';
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

  Future<void> _choosePhoto({ImageSource source = ImageSource.camera}) async {
    if (_isPickingPhoto) return;
    _isPickingPhoto = true;
    try {
      final pickPhoto = widget.pickPhoto;
      final picked = source == ImageSource.camera && pickPhoto != null
          ? await pickPhoto()
          : await ImagePicker().pickImage(
              source: source,
              maxWidth: 1800,
              imageQuality: 90,
            );
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

  void _handleBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    context.pop();
  }

  void _uploadAnother() {
    setState(() {
      _draft = null;
      _draftBytes = null;
      _draftError = null;
    });
    BlocProvider.of<DocumentUploadCubit>(context).reset();
  }

  String _reviewStatusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'pending' || '' => 'Pending review',
      'approved' => 'Approved',
      'rejected' => 'Needs resubmission',
      _ => status,
    };
  }

  Widget _buildCompletionView(BuildContext context, DriverDocument document) {
    final colors = context.colorScheme;
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: AppCompletionView(
          key: const ValueKey('driver-document-upload-complete'),
          title: 'Document submitted',
          message:
              'Your ${document.type.label.toLowerCase()} has been uploaded and is waiting for verification.',
          summary: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DocumentSummaryRow(
                  label: 'Document',
                  value: document.type.label,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(
                    height: 1,
                    color: colors.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                _DocumentSummaryRow(
                  label: 'Status',
                  value: _reviewStatusLabel(document.status),
                  valueColor: context.semanticColors.info,
                ),
              ],
            ),
          ),
          footnote: 'We will notify you once your document review is complete.',
          primaryActionLabel: 'Done',
          onPrimaryAction: _handleBack,
          secondaryActionLabel: 'Upload another',
          onSecondaryAction: _uploadAnother,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return BlocListener<DocumentUploadCubit, DocumentUploadState>(
      listener: (context, state) {
        if (state.status == DocumentUploadStatus.succeeded) {
          unawaited(HapticFeedback.mediumImpact());
          setState(() {
            _draft = null;
            _draftBytes = null;
            _draftError = null;
          });
        } else if (state.status == DocumentUploadStatus.failed) {
          setState(() => _draftError = state.message);
        }
      },
      child: AppSecondaryPage(
        title: 'Driver Documents',
        onBack: _handleBack,
        maxWidth: 560,
        child: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
          builder: (context, state) {
            if (state.status == DocumentUploadStatus.succeeded &&
                state.document != null) {
              return _buildCompletionView(context, state.document!);
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? AppLayout.pagePadding
                    : AppLayout.pagePaddingWide;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.sm,
                    horizontalPadding,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      DocumentTypeSelector(
                        selected: _type,
                        enabled: !state.isUploading,
                        onSelected: (next) => setState(() {
                          _type = next;
                          _draftError = null;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DocumentPhotoPreview(
                        bytes: _draftBytes,
                        isUploading: state.isUploading,
                        onChoosePhoto: _choosePhoto,
                      ),
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
                          onPressed: state.isUploading
                              ? null
                              : () => _choosePhoto(source: ImageSource.camera),
                          style:
                              OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                                enableFeedback: false,
                                splashFactory: NoSplash.splashFactory,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
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
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: AppSize.controlHeight,
                        child: OutlinedButton.icon(
                          key: const ValueKey('driver-document-choose-gallery'),
                          onPressed: state.isUploading
                              ? null
                              : () => _choosePhoto(source: ImageSource.gallery),
                          style:
                              OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                                enableFeedback: false,
                                splashFactory: NoSplash.splashFactory,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
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
                          icon: const Icon(LucideIcons.image, size: 17),
                          label: const Text('Choose from gallery'),
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
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class const _DocumentSummaryRow({
  required this.label,
  required this.value,
  this.valueColor,
}) extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textStyles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: textStyles.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textStyles.bodyMedium?.copyWith(
              color: valueColor ?? colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
