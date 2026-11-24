import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  String? _selectedGender;
  DateTime? _selectedDob;
  String? _avatarPath;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get('/customer/profile');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      _firstNameController.text = data['first_name']?.toString() ?? '';
      _lastNameController.text = data['last_name']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _selectedGender = data['gender']?.toString();
      _avatarPath = data['avatar']?.toString();

      if (data['date_of_birth'] != null) {
        _selectedDob = DateTime.tryParse(data['date_of_birth'].toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: ${ApiClient.parseError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final filename = pickedFile.path.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(pickedFile.path, filename: filename),
      });

      final response = await dio.post('/customer/profile/avatar', data: formData);
      final newAvatarPath = response.data['data']?['avatar']?.toString();

      if (newAvatarPath != null) {
        setState(() => _avatarPath = newAvatarPath);
        await ref.read(authProvider.notifier).checkAuth();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!'), backgroundColor: kSuccess),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: ${ApiClient.parseError(e)}'), backgroundColor: kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final payload = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_selectedGender != null) 'gender': _selectedGender,
        if (_selectedDob != null) 'date_of_birth': DateFormat('yyyy-MM-dd').format(_selectedDob!),
      };

      await dio.put('/customer/profile', data: payload);
      await ref.read(authProvider.notifier).checkAuth();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: kSuccess),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.parseError(e)), backgroundColor: kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password', style: TextStyle(color: kNavy, fontWeight: FontWeight.bold)),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: currentPasswordCtrl,
                    label: 'Current Password',
                    isPassword: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: newPasswordCtrl,
                    label: 'New Password (min 8 chars)',
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: confirmPasswordCtrl,
                    label: 'Confirm New Password',
                    isPassword: true,
                    validator: (v) {
                      if (v != newPasswordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!dialogFormKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);

                      try {
                        final dio = ref.read(apiClientProvider).dio;
                        await dio.put('/customer/profile/password', data: {
                          'current_password': currentPasswordCtrl.text,
                          'password': newPasswordCtrl.text,
                          'password_confirmation': confirmPasswordCtrl.text,
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully.'),
                              backgroundColor: kSuccess,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ApiClient.parseError(e)),
                              backgroundColor: kDanger,
                            ),
                          );
                        }
                      } finally {
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiClient.apiImage(_avatarPath);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(kPad),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Image & Upload Button
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.paleOrange,
                            child: avatarUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person, size: 50, color: AppColors.primaryOrange),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploadingAvatar ? null : _handlePickAndUploadAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingAvatar
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // First Name & Last Name
                    CustomTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'First name is required';
                        if (v.trim().length > 100) return 'Max 100 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Last name is required';
                        if (v.trim().length > 100) return 'Max 100 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v != null && v.trim().length > 20) return 'Max 20 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Selection
                    const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kNavy)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      hint: const Text('Select Gender'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth Selection
                    const Text('Date of Birth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kNavy)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDob ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now().subtract(const Duration(days: 1)),
                        );
                        if (pickedDate != null) {
                          setState(() => _selectedDob = pickedDate);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : 'Select Date of Birth',
                              style: TextStyle(color: _selectedDob != null ? kNavy : Colors.grey[600], fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryOrange),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _handleSaveProfile,
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Change Password Section Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryOrange),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryOrange),
                        label: const Text('Change Password', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
