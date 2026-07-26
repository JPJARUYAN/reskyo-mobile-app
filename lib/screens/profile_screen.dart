import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _fullNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _barangayController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  String _email = '';
  UserRole _role = UserRole.resident;
  ResponderStatus _responderStatus = ResponderStatus.offline;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    _barangayController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (user != null && mounted) {
        setState(() {
          _fullNameController.text = user.fullName;
          _contactController.text = user.contactNumber;
          _barangayController.text = user.barangay;
          _email = user.email;
          _role = user.role;
          _responderStatus = ResponderStatus.values.firstWhere(
            (s) => s.name == user.responderStatus,
            orElse: () => ResponderStatus.offline,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading profile: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final user = await _authService.getCurrentUserProfile();
      if (user == null) return;

      final updated = user.copyWith(
        fullName: _fullNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        barangay: _barangayController.text.trim(),
      );

      await _authService.updateProfile(updated);

      if (mounted) {
        setState(() => _isEditing = false);
        showSnackBar(context, 'Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleResponderStatus(ResponderStatus status) async {
    try {
      await _authService.updateResponderStatus(status);
      setState(() => _responderStatus = status);
      if (mounted) {
        showSnackBar(context, 'Status updated to ${status.label}');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: AppSpacing.lg),
            _buildRoleBadge(),
            if (_role == UserRole.responder) ...[
              const SizedBox(height: AppSpacing.md),
              _buildAvailabilitySection(),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildProfileForm(),
            const SizedBox(height: AppSpacing.lg),
            _buildSignOutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primaryDark,
      child: Text(
        _fullNameController.text.isNotEmpty
            ? _fullNameController.text[0].toUpperCase()
            : '?',
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: (_role == UserRole.responder ? AppColors.success : AppColors.info).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: (_role == UserRole.responder ? AppColors.success : AppColors.info).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _role == UserRole.responder ? Icons.volunteer_activism : Icons.person,
            size: 18,
            color: _role == UserRole.responder ? AppColors.success : AppColors.info,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _role == UserRole.responder ? 'Volunteer Responder' : 'Resident',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _role == UserRole.responder ? AppColors.success : AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Availability Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: ResponderStatus.values.map((status) {
              final isActive = status == _responderStatus;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: OutlinedButton(
                    onPressed: () => _toggleResponderStatus(status),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? Colors.white : status.color,
                      backgroundColor: isActive ? status.color : Colors.transparent,
                      side: BorderSide(color: status.color),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == ResponderStatus.available
                              ? Icons.check_circle
                              : status == ResponderStatus.busy
                                  ? Icons.pause_circle
                                  : Icons.offline_bolt,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(status.label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              if (_isEditing)
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildField('Email', _email, Icons.email_outlined, enabled: false),
          const SizedBox(height: AppSpacing.sm),
          _buildField('Full Name', _fullNameController.text, Icons.person_outlined,
              controller: _fullNameController, enabled: _isEditing),
          const SizedBox(height: AppSpacing.sm),
          _buildField('Contact Number', _contactController.text, Icons.phone_outlined,
              controller: _contactController, enabled: _isEditing, keyboardType: TextInputType.phone),
          const SizedBox(height: AppSpacing.sm),
          _buildField('Barangay', _barangayController.text, Icons.location_city_outlined,
              controller: _barangayController, enabled: _isEditing),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String value,
    IconData icon, {
    TextEditingController? controller,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    if (controller != null && enabled) {
      controller.text = value;
    }

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : AppColors.textSecondary.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return DangerZoneCard(
      title: 'Account',
      subtitle: 'Sign out of your RESKYO account',
      buttonText: 'Sign Out',
      onPressed: _signOut,
    );
  }
}
