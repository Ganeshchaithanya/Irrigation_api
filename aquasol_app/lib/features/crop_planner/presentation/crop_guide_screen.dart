import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/services/api_service.dart';

final planningLoadingProvider = StateProvider<bool>((ref) => false);
final planResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

class CropGuideScreen extends ConsumerWidget {
  const CropGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text(AppLocalizations.get('Crop Guide', lang), 
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('AI-powered seasonal crop planning and suitability analysis.', 
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                _buildPlanningCard(context, ref, lang),
                const SizedBox(height: 32),
                Text(AppLocalizations.get('Recommended Crops', lang), 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                _buildCropList(lang),
                const SizedBox(height: 140),
              ],
            ),
          ),
          const GlassNav(currentPath: '/planner'),
        ],
      ),
    );
  }

  Widget _buildPlanningCard(BuildContext context, WidgetRef ref, String lang) {
    final isLoading = ref.watch(planningLoadingProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.emeraldGradient,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.emerald.withAlpha(60), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.sparkles, color: Colors.white, size: 32),
          const SizedBox(height: 20),
          Text(AppLocalizations.get('New Season Planning', lang), 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Aura AI has analyzed your soil cycles and previous yields to recommend the best Kharif strategy.', 
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : () => _startAIPlanning(context, ref, lang),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.emerald,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald))
              : Text(AppLocalizations.get('Start AI Planning', lang), style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _startAIPlanning(BuildContext context, WidgetRef ref, String lang) async {
    ref.read(planningLoadingProvider.notifier).state = true;
    
    try {
      final farmAsync = ref.read(farmProvider);
      if (!farmAsync.hasValue || farmAsync.value == null) return;
      
      final zones = farmAsync.value!.acres.expand((a) => a.zones).toList();
      if (zones.isEmpty) throw Exception("No zones found for planning");
      
      final result = await ApiService().generateCropPlan(zones.first.id);
      ref.read(planResultProvider.notifier).state = result;
      
      if (context.mounted) {
        _showPlanResult(context, result, lang);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Planning failed: $e"), backgroundColor: AppColors.danger));
      }
    } finally {
      ref.read(planningLoadingProvider.notifier).state = false;
    }
  }

  void _showPlanResult(BuildContext context, Map<String, dynamic> plan, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(LucideIcons.sparkles, color: AppColors.emerald, size: 32),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const SizedBox(height: 20),
              Text(plan['recommended_crop'] ?? 'Strategy', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.emerald.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Text("Yield: ${plan['expected_yield']} t/ha", style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 24),
              const Text('AI Reasoning', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              Text(plan['reasoning'] ?? '', style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
              const SizedBox(height: 24),
              _buildPlanSection(LucideIcons.droplets, 'Irrigation Strategy', plan['irrigation_strategy']),
              const SizedBox(height: 16),
              _buildPlanSection(LucideIcons.flaskConical, 'Fertilizer Plan', plan['fertilizer_plan']),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Update Farm Strategy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSection(IconData icon, String title, dynamic data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.emerald),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (data is Map)
            ...data.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text("• ${e.key}: ${e.value}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ))
          else
            Text(data.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCropList(String lang) {
    final crops = [
      {
        'name': 'Maize (Corn)',
        'suitability': '94%',
        'stages': 'Vegetative',
        'water': 'Medium',
        'icon': LucideIcons.wheat,
        'color': AppColors.warning
      },
      {
        'name': 'Groundnut',
        'suitability': '88%',
        'stages': 'Flowering',
        'water': 'Low',
        'icon': LucideIcons.nut,
        'color': AppColors.success
      },
      {
        'name': 'Wheat',
        'suitability': '82%',
        'stages': 'Harvesting',
        'water': 'High',
        'icon': LucideIcons.wheat,
        'color': AppColors.info
      },
    ];

    return Column(
      children: crops.map((crop) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: (crop['color'] as Color).withAlpha(20), borderRadius: BorderRadius.circular(16)),
              child: Icon(crop['icon'] as IconData, color: crop['color'] as Color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crop['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(crop['stages'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Suitability: ${crop['suitability']}', style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
          ],
        ),
      )).toList(),
    );
  }
}
