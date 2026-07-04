/// Profile Info Screen: lets passengers view and update their profile details in the database.
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passenger_app/shared/widgets/custom_toast.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController(text: 'Pagadian City, Zamboanga del Sur');
  bool _isEditing = false;
  String _passengerId = '';

  String? _nameError;
  String? _phoneError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _passengerId = prefs.getString('passenger_id') ?? '';
      _nameController.text = prefs.getString('passenger_name') ?? 'Xyrel Tenefrancia';
      _phoneController.text = prefs.getString('passenger_phone') ?? '+63 912 345 6789';
      _emailController.text = prefs.getString('passenger_email') ?? 'xyrel@baoride.com';
    });
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
        final updated = await PassengerApiService.updateProfile(
          id: _passengerId,
          name: name,
          phone: phone,
          email: email,
        );
        if (updated != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('passenger_name', updated['name'] as String);
          await prefs.setString('passenger_phone', updated['phone'] as String);
          await prefs.setString('passenger_email', updated['email'] as String);

          if (!mounted) return;
          CustomToast.show(context, 'Profile updated successfully!');
        } else {
          if (!mounted) return;
          CustomToast.show(context, 'Failed to update profile details.', isError: true);
        }
      } catch (e) {
        if (!mounted) return;
        CustomToast.show(context, 'Connection failed: $e', isError: true);
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
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
                      border: Border.all(color: AppTheme.borderSide, width: 2),
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildField('Full Name', _nameController, LucideIcons.user, errorText: _nameError),
            const SizedBox(height: 16),
            _buildField('Phone Number', _phoneController, LucideIcons.phone, errorText: _phoneError),
            const SizedBox(height: 16),
            _buildField('Email', _emailController, LucideIcons.mail, errorText: _emailError),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
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
            errorStyle: TextStyle(color: AppTheme.cancel),
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
              borderSide: BorderSide(color: AppTheme.cancel),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.cancel,
                width: 1.5,
              ),
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
