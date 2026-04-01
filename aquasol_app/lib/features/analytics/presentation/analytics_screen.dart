import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const GlassNav(currentPath: '/analytics'),
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
          Text(AppLocalizations.get('Analytics', lang), 
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          _buildUsageChart(lang),
          const SizedBox(height: 24),
          _buildMoistureTrendChart(lang),
          const SizedBox(height: 32),
          Text(AppLocalizations.get('AI Insights', lang), 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _buildAiInsightsList(lang),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildUsageChart(String lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.get('Weekly Water Usage', lang), 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 1200), FlSpot(1, 1500), FlSpot(2, 1100), FlSpot(3, 1800), FlSpot(4, 1400), FlSpot(5, 2000), FlSpot(6, 1700)],
                    isCurved: true,
                    color: AppColors.emerald,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppColors.emerald.withAlpha(20)),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mon', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Wed', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Fri', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Sun', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoistureTrendChart(String lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.get('Moisture Trend', lang), 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 40), FlSpot(1, 45), FlSpot(2, 42), FlSpot(3, 48), FlSpot(4, 44)],
                    isCurved: true,
                    color: AppColors.emerald,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [FlSpot(0, 38), FlSpot(1, 40), FlSpot(2, 35), FlSpot(3, 30), FlSpot(4, 25)],
                    isCurved: true,
                    color: AppColors.danger.withAlpha(100),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _legendItem('Recorded', AppColors.emerald),
              const SizedBox(width: 16),
              _legendItem('Predicted', AppColors.danger.withAlpha(100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAiInsightsList(String lang) {
    final insights = [
      {'title': AppLocalizations.get('Efficiency Improved', lang), 'value': '18%', 'icon': LucideIcons.trendingUp, 'color': AppColors.success},
      {'title': AppLocalizations.get('Water Saved', lang), 'value': '240L', 'icon': LucideIcons.droplet, 'color': AppColors.info},
      {'title': AppLocalizations.get('Soil Health', lang), 'value': 'Excellent', 'icon': LucideIcons.sprout, 'color': AppColors.success},
    ];

    return Column(
      children: insights.map((insight) => Container(
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
              decoration: BoxDecoration(color: (insight['color'] as Color).withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(insight['icon'] as IconData, color: insight['color'] as Color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(insight['title'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const Spacer(),
            Text(insight['value'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.emerald)),
          ],
        ),
      )).toList(),
    );
  }
}
