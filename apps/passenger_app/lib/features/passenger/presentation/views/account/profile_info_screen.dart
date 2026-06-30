/// Profile Info Screen: lets passengers view and update their profile details in the database.
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (_isEditing) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();

      if (name.isEmpty || phone.isEmpty || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill out all fields.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile details.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surface, width: 2),
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
            _buildField('Full Name', _nameController, LucideIcons.user),
            const SizedBox(height: 16),
            _buildField('Phone Number', _phoneController, LucideIcons.phone),
            const SizedBox(height: 16),
            _buildField('Email', _emailController, LucideIcons.mail),
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
    IconData icon,
  ) {
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
        Container(
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isEditing
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : AppTheme.borderSide,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: _isEditing,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                size: 18,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
