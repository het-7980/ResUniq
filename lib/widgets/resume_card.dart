/// ---------------------------------------------------------------------------
/// ResUniq - resume_card.dart
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

import 'package:flutter/material.dart';
import '../models/resume_document.dart';
import '../theme/app_theme.dart';

/// Card representing a single resume in the "My Resumes" list.
/// Shows a template preview swatch, title, last-edited date, a status
/// badge, and a three-dot overflow menu with Edit / Duplicate /
/// Preview / Download PDF / Delete actions.
class ResumeCard extends StatelessWidget {
  final ResumeDocument resume;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDownload;
  final VoidCallback? onPreview;
  final VoidCallback? onDelete;

  const ResumeCard({
    super.key,
    required this.resume,
    this.onTap,
    this.onEdit,
    this.onRename,
    this.onDuplicate,
    this.onDownload,
    this.onPreview,
    this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = resume.isComplete;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resume.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                onEdit?.call();
                                break;
                              case 'rename':
                                onRename?.call();
                                break;
                              case 'duplicate':
                                onDuplicate?.call();
                                break;
                              case 'download':
                                onDownload?.call();
                                break;
                              case 'preview':
                                onPreview?.call();
                                break;
                              case 'delete':
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder:
                              (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 10),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.drive_file_rename_outline,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Rename'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy_outlined, size: 18),
                                      SizedBox(width: 10),
                                      Text('Duplicate'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'preview',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.remove_red_eye_outlined,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Preview'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'download',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.file_download_outlined,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Download PDF'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edited ${_formatDate(resume.updatedAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isComplete
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            isComplete ? 'Complete' : 'Draft',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isComplete
                                      ? AppColors.success
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: resume.completion,
                              minHeight: 5,
                              backgroundColor: AppColors.secondaryBackground,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
