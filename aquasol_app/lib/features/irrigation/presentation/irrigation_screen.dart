import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';

class IrrigationScreen extends ConsumerStatefulWidget {
  const IrrigationScreen({super.key});

  @override
  ConsumerState<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends ConsumerState<IrrigationScreen> {
  bool _isAuto = true;

  @override
  Widget build(BuildContext context) {
    final farmAsync = ref.watch(farmProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          farmAsync.when(
            data: (farm) => _buildContent(context, lang),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
          ),
          const GlassNav(currentPath: '/irrigation'),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(AppLocalizations.get('Irrigation Control', lang), 
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          _buildModeToggle(),
          const SizedBox(height: 32),
          const Text('Irrigation Schedule', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _buildScheduleList(),
          const SizedBox(height: 32),
          _buildWaterBudgetCard(),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAuto = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _isAuto ? AppColors.emerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text('Auto', 
                  style: TextStyle(color: _isAuto ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAuto = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: !_isAuto ? AppColors.emerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text('Manual', 
                  style: TextStyle(color: !_isAuto ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    final zones = ref.watch(allZonesProvider);

    if (zones.isEmpty) {
      return const Center(child: Text('No zones configured.'));
    }

    return Column(
      children: zones.map((z) => Container(
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.emerald.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.clock, color: AppColors.emerald, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(z.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Text('Scheduled: 04:00 AM', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            Switch(
              value: z.moisture < 30, // Example logic for active status
              onChanged: (v) {},
              activeThumbColor: AppColors.emerald,
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildWaterBudgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Water Budget', 
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: const Text('Efficient', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(color: AppColors.emerald, value: 45, radius: 25, showTitle: false),
                      PieChartSectionData(color: AppColors.emerald.withAlpha(50), value: 55, radius: 25, showTitle: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _budgetLegend('Consumed', '3,200L', AppColors.emerald),
                  const SizedBox(height: 16),
                  _budgetLegend('Remaining', '6,800L', AppColors.emerald.withAlpha(50)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgetLegend(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
