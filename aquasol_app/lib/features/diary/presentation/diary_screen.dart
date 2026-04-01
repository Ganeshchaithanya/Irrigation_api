import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';

import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/providers/diary_provider.dart';
import 'package:aquasol_app/services/api_service.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';
import 'package:intl/intl.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSaving = false;

  void _showAddLogBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Farm Activity', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text('Manually record fertilizers, pest control, or field observations.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Activity Title',
                  hintText: 'e.g. Applied Pesticide',
                  prefixIcon: const Icon(LucideIcons.edit2, color: AppColors.emerald),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Notes on chemical used, dosage, or targeted zones...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_titleController.text.trim().isEmpty) return;
                          
                          setSheetState(() => _isSaving = true);
                          try {
                            // Link log specifically to this user's farm
                            final farmAsync = ref.read(farmProvider);
                            if (!farmAsync.hasValue || farmAsync.value == null) {
                              throw Exception("Farm ID not loaded");
                            }
                            final farmId = farmAsync.value!.id;
                            
                            await ApiService().createFarmLog(
                              farmId: farmId.toString(),
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                            );
                            
                            _titleController.clear();
                            _descController.clear();
                            ref.invalidate(diaryLogsProvider); // Refresh list
                            
                            if (context.mounted) {
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Activity logged securely to the cloud!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            setSheetState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving ? const CircularProgressIndicator(color: AppColors.emerald) : const Text('Save to Cloud Diary'),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(diaryLogsProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          logsAsync.when(
            data: (logs) => _buildContent(context, logs, lang),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
          ),
          const GlassNav(currentPath: '/diary'),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Map<String, dynamic>> logs, String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.get('Farm Diary', lang), 
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              _buildAddLogButton(context),
            ],
          ),
          const SizedBox(height: 8),
          const Text('A chronological record of farm operations.', 
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          if (logs.isEmpty)
             _buildEmptyState()
          else
            ...logs.asMap().entries.map((entry) => _buildTimelineItem(entry.value, entry.key, logs.length)),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 80),
        Icon(LucideIcons.bookOpen, size: 64, color: AppColors.textSecondary.withAlpha(50)),
        const SizedBox(height: 24),
        const Text('Your farm diary is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Start recording activities to track your progress.', 
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAddLogButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _showAddLogBottomSheet,
      icon: const Icon(LucideIcons.plus, size: 18),
      label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'sparkles': return LucideIcons.sparkles;
      case 'droplets': return LucideIcons.droplets;
      case 'flaskConical': return LucideIcons.flaskConical;
      case 'cloudRain': return LucideIcons.cloudRain;
      case 'sprout': return LucideIcons.sprout;
      default: return LucideIcons.edit2;
    }
  }

  Color _getColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.emerald;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "Unknown Date";
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('MMM dd, hh:mm a').format(dt);
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, int index, int totalLength) {
    final bool isLast = index == totalLength - 1;
    final color = _getColor(event['color_hex']);
    final icon = _getIconData(event['icon_name']);
    final dateStr = _formatDate(event['created_at']);

    return FadeInLeft(
      delay: Duration(milliseconds: 100 * index),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + icon
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withAlpha(100), width: 1.5),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withAlpha(150),
                            Colors.grey.shade300,
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24), // Space after last item
              ],
            ),
            const SizedBox(width: 16),
            // Event content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: AppColors.textSecondary.withAlpha(180),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['title'] ?? 'Activity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event['description'] ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
