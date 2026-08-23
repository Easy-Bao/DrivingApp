import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/profile/data/datasources/passenger_profile_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;
  String _passengerId = '';

  String? _nameError;
  String? _phoneError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final session = Modular.get<SecureSessionService>();
    final prefs = await SharedPreferences.getInstance();
    final pId = await session.readPassengerId() ?? '';
    final cachedValues = <String, String>{
      'name': prefs.getString('passenger_name') ?? '',
      'phone': prefs.getString('passenger_phone') ?? '',
      'email': prefs.getString('passenger_email') ?? '',
      'address': prefs.getString('passenger_address') ?? '',
    };

    if (!mounted) return;
    setState(() {
      _passengerId = pId;
      _applyProfileValues(cachedValues);
    });

    if (pId.isEmpty) return;

    try {
      final response = await Modular.get<PassengerProfileRemoteDataSource>()
          .fetchProfile(pId);
      final profile = ProfileModel.fromJson(response);
      final values = <String, String>{
        'name': profile.name.isNotEmpty
            ? profile.name
            : cachedValues['name'] ?? '',
        'phone': profile.phone.isNotEmpty
            ? profile.phone
            : cachedValues['phone'] ?? '',
        'email': profile.email.isNotEmpty
            ? profile.email
            : cachedValues['email'] ?? '',
        'address': profile.address.isNotEmpty
            ? profile.address
            : cachedValues['address'] ?? '',
      };
      await prefs.setString('passenger_name', values['name']!);
      await prefs.setString('passenger_phone', values['phone']!);
      await prefs.setString('passenger_email', values['email']!);
      await prefs.setString('passenger_address', values['address']!);
      if (!mounted) return;
      setState(() => _applyProfileValues(values));
    } catch (_) {
      // Cached values remain visible when the profile service is unavailable.
    }
  }

  void _applyProfileValues(Map<String, String> values) {
    _nameController.text = values['name'] ?? '';
    _phoneController.text = values['phone'] ?? '';
    _emailController.text = values['email'] ?? '';
    _addressController.text = values['address'] ?? '';
  }

  Future<void> _toggleEdit() async {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
    });

    if (_isEditing) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();

      bool hasError = false;
      if (name.isEmpty) {
        setState(() => _nameError = 'Name is required');
        hasError = true;
      }
      if (phone.isEmpty) {
        setState(() => _phoneError = 'Phone is required');
        hasError = true;
      }
      if (email.isEmpty) {
        setState(() => _emailError = 'Email is required');
        hasError = true;
      } else if (!email.contains('@')) {
        setState(() => _emailError = 'Please enter a valid email');
        hasError = true;
      }

      if (hasError) {
        return;
      }

      try {
        final updated = await Modular.get<PassengerProfileRemoteDataSource>()
            .updateProfile(
              passengerId: _passengerId,
              data: {
                'name': name,
                'phone': phone,
                'email': email,
                'address': _addressController.text.trim(),
              },
            );
        if (updated.isNotEmpty) {
          if (!mounted) return;
          CustomToast.show(context, 'Profile updated successfully!');
        }
      } catch (error) {
        if (!mounted) return;
        CustomToast.show(
          context,
          'We could not update your profile. Please try again.',
          isError: true,
        );
      }
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: const Icon(
              LucideIcons.arrow_left,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Profile Info',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.neutralColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.borderSide,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              size: 16,
                              color: AppTheme.surface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildField(
                  'Full Name',
                  _nameController,
                  LucideIcons.user,
                  errorText: _nameError,
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Phone Number',
                  _phoneController,
                  LucideIcons.phone,
                  errorText: _phoneError,
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Email',
                  _emailController,
                  LucideIcons.mail,
                  errorText: _emailError,
                ),
                const SizedBox(height: 16),
                _buildField('Address', _addressController, LucideIcons.map_pin),
                const SizedBox(height: 32),
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _toggleEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.activeControlForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          decoration: InputDecoration(
            errorText: errorText,
            errorStyle: const TextStyle(color: AppTheme.cancel),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
            filled: false,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _isEditing
                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                    : AppTheme.borderSide,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.borderSide),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.cancel),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.cancel, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
