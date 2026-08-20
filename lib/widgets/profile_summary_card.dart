/// ---------------------------------------------------------------------------
/// ResUniq - profile_summary_card.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Reusable UI widgets shared by multiple screens. Keeping these widgets here avoids duplicating UI code.
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large rounded card shown at the top of the Home screen summarising
/// the user's profile: picture, name, email, profession, resume count
/// and overall completion percentage, plus an "Edit Profile" action.
class ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String email;
  final String profession;
  /// Decoded bytes of the user's uploaded profile photo.
  /// When null, the card displays the default person icon.
  final Uint8List? profileImageBytes;
  final int resumeCount;
  final double completion; // 0.0 - 1.0
  final VoidCallback onEditProfile;

  const ProfileSummaryCard({
    super.key,
    required this.name,
    required this.email,
    required this.profession,
    this.profileImageBytes,
    required this.resumeCount,
    required this.completion,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                backgroundImage: profileImageBytes != null
                    ? MemoryImage(profileImageBytes!)
                    : null,
                child: profileImageBytes == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profession,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatBlock(label: 'Resumes', value: '$resumeCount'),
                ),
                const SizedBox(width: 20),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white24,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _StatBlock(
                    label: 'Completion',
                    value: '${(completion * 100).round()}%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onEditProfile,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: Colors.white54),
                foregroundColor: Colors.white,
              ),
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }
}

/// _StatBlock is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
