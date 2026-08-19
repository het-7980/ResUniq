/// ---------------------------------------------------------------------------
/// ResUniq - edit_profile_screen.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// User profile display and profile-editing screens.
///
/// BEGINNER GUIDE:
/// - UI screens/widgets should mainly display information and collect input.
/// - Providers hold/change state that the UI listens to.
/// - Services/repositories perform Firebase, API, PDF, or other data work.
/// - Models describe the data passed between these layers.
///
/// TIP:
/// Read this file together with the classes it imports. The imported classes
/// usually explain where data comes from and where actions are performed.
/// ---------------------------------------------------------------------------
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/personal_details_service.dart';
import '../../services/profile_picture_service.dart';
import '../../theme/app_theme.dart';

/// EditProfileScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// _EditProfileScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  Uint8List? _profileImageBytes;
  String _profileImageUrl = '';
  bool _removeProfileImage = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final personal = await PersonalDetailsService().getDetails(user.uid);

      String name = personal?['name'] as String? ?? '';
      final email = user.email ?? '';

      // Existing accounts may not have the new personal-details document yet.
      // Fall back to users/{uid} and let Save create the new document.
      if (name.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        name = userDoc.data()?['name'] as String? ?? '';
      }

      _nameController.text = name;
      _emailController.text = email;
      _phoneController.text = personal?['phone'] as String? ?? '';
      _profileImageUrl =
          personal?['profileImageUrl']?.toString() ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 900,
      maxHeight: 900,
    );

    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _profileImageBytes = bytes;
      _removeProfileImage = false;
    });
  }

  Future<void> _removeProfilePicture() async {
    setState(() {
      _profileImageBytes = null;
      _profileImageUrl = '';
      _removeProfileImage = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await PersonalDetailsService().saveDetails(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: user.email ?? '',
        phone: _phoneController.text.trim(),
        profileImageBytes: _profileImageBytes,
        removeProfileImage: _removeProfileImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to update profile.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBackground,
        surfaceTintColor: AppColors.secondaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  12,
                  AppSpacing.page,
                  32,
                ),
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            shape: BoxShape.circle,
                            image: _profileImageBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_profileImageBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : (() {
                                    final bytes =
                                        ProfilePictureService.decode(
                                      _profileImageUrl,
                                    );
                                    return bytes == null
                                        ? null
                                        : DecorationImage(
                                            image: MemoryImage(bytes),
                                            fit: BoxFit.cover,
                                          );
                                  })(),
                          ),
                          child: _profileImageBytes == null &&
                                  _profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 46,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _saving ? null : _pickProfileImage,
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      spacing: 6,
                      children: [
                        TextButton.icon(
                          onPressed: _saving ? null : _pickProfileImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _profileImageBytes != null ||
                                    _profileImageUrl.isNotEmpty
                                ? 'Change Photo'
                                : 'Add Photo',
                          ),
                        ),
                        if (_profileImageBytes != null ||
                            _profileImageUrl.isNotEmpty)
                          TextButton(
                            onPressed:
                                _saving ? null : _removeProfilePicture,
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Personal Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update the information used in your profile and resumes.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return 'Please enter your name';
                      if (name.length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                      suffixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) return 'Please enter your phone number';
                      return RegExp(r'^\d{10}$').hasMatch(phone)
                          ? null
                          : 'Phone number must be exactly 10 digits';
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
