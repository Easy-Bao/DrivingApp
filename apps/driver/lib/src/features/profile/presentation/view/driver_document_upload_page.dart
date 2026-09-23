import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/presentation/bloc/document_upload/driver_document_upload_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:image_picker/image_picker.dart';

class const DriverDocumentUploadPage({super.key, this.pickPhoto, this.onBack})
    extends StatefulWidget {
  final Future<XFile?> Function()? pickPhoto;
  final VoidCallback? onBack;

  @override
  State<DriverDocumentUploadPage> createState() =>
      _DriverDocumentUploadPageState();
}

class _DriverDocumentUploadPageState extends State<DriverDocumentUploadPage> {
  DriverDocumentType _type = DriverDocumentType.driverLicense;
  XFile? _draft;
  String? _draftError;

  Future<void> _choosePhoto() async {
    final picked = widget.pickPhoto == null
        ? await ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: 1800,
            imageQuality: 90,
          )
        : await widget.pickPhoto!();
    if (!mounted || picked == null) return;
    setState(() {
      _draft = picked;
      _draftError = null;
    });
    BlocProvider.of<DriverDocumentUploadCubit>(context).reset();
  }

  Future<void> _submit() async {
    final draft = _draft;
    if (draft == null) return;
    final contentType = _contentType(draft);
    if (contentType == null) {
      setState(() => _draftError = 'Choose a JPEG or PNG photo.');
      return;
    }
    final bytes = await draft.readAsBytes();
    if (!mounted) return;
    await BlocProvider.of<DriverDocumentUploadCubit>(context)
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
    return BlocListener<DriverDocumentUploadCubit, DriverDocumentUploadState>(
      listener: (context, state) {
        if (state.status == DriverDocumentUploadStatus.succeeded) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Document submitted for review.')),
            );
          setState(() => _draft = null);
        } else if (state.status == DriverDocumentUploadStatus.failed) {
          setState(() => _draftError = state.message);
        }
      },
      child: Scaffold(
        backgroundColor: context.canvasColor,
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: widget.onBack ?? () => context.pop(),
            icon: const Icon(LucideIcons.arrow_left),
          ),
          title: const Text('Driver Documents'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(EasyRideLayout.pagePaddingWide),
                children: [
                  Text(
                    'Submit a clear photo for review',
                    style: context.textStyles.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your photo stays on this screen until you confirm the upload.',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: EasyRideSpacing.xl),
                  SegmentedButton<DriverDocumentType>(
                    segments: [
                      ButtonSegment(
                        value: DriverDocumentType.driverLicense,
                        label: const Text("Driver's license"),
                        icon: const Icon(LucideIcons.id_card),
                      ),
                      ButtonSegment(
                        value: DriverDocumentType.vehicleRegistration,
                        label: const Text('Vehicle registration'),
                        icon: const Icon(LucideIcons.file_text),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      setState(() => _type = selection.first);
                    },
                  ),
                  const SizedBox(height: EasyRideSpacing.xl),
                  _buildPreview(context),
                  if (_draftError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _draftError!,
                      key: const ValueKey('driver-document-upload-error'),
                      style: TextStyle(color: context.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: EasyRideSpacing.xl),
                  OutlinedButton.icon(
                    key: const ValueKey('driver-document-choose-photo'),
                    onPressed:
                        context
                            .watch<DriverDocumentUploadCubit>()
                            .state
                            .isUploading
                        ? null
                        : _choosePhoto,
                    icon: const Icon(LucideIcons.camera),
                    label: Text(
                      _draft == null ? 'Take a photo' : 'Retake photo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<
                    DriverDocumentUploadCubit,
                    DriverDocumentUploadState
                  >(
                    builder: (context, state) => ElevatedButton(
                      key: const ValueKey('driver-document-submit'),
                      onPressed: _draft == null || state.isUploading
                          ? null
                          : _submit,
                      child: state.isUploading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit document'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final draft = _draft;
    if (draft == null) {
      return Container(
        key: const ValueKey('driver-document-empty-preview'),
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Text(
          'No photo selected',
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return FutureBuilder<Uint8List>(
      key: const ValueKey('driver-document-photo-preview'),
      future: draft.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
          child: Image.memory(
            snapshot.data!,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              height: 220,
              alignment: Alignment.center,
              color: context.colorScheme.surfaceContainerHighest,
              child: const Text('Preview unavailable'),
            ),
          ),
        );
      },
    );
  }
}
