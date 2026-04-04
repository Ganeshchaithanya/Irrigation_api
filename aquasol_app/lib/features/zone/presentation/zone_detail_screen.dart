import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/models/zone_model.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/services/api_service.dart';
import 'package:animate_do/animate_do.dart';

class ZoneDetailScreen extends ConsumerWidget {
  final String zoneId;
  const ZoneDetailScreen({super.key, required this.zoneId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ZONE $zoneId TOPOGRAPHY', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyDeep, fontSize: 16, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.navyDeep),
          onPressed: () => context.pop(),
        ),
      ),
      body: farmAsync.when(
        data: (farm) {
          final zones = farm.acres.expand((a) => a.zones).toList();
          final zone = zones.firstWhere(
            (z) => z.id == zoneId,
            orElse: () => _emptyZone(zoneId),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildStressHero(zone),
                const SizedBox(height: 32),
                _buildSensorGrid(zone),
                const SizedBox(height: 32),
                _buildTemporalIntelligence(zone),
                const SizedBox(height: 48),
                const Text('Topographic Nodes', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navyDeep)),
                const SizedBox(height: 16),
                _buildAdvancedTelemetryList(zone),
                const SizedBox(height: 40),
                _buildMoistureTrend(zone),
                const SizedBox(height: 40),
                _buildPlantStageLink(context, zone),
                const SizedBox(height: 40),
                _buildActionButtons(context, ref, zone),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandEmerald)),
        error: (e, _) => Center(child: Text("Sync Error: $e", style: const TextStyle(color: AppColors.danger))),
      ),
    );
  }

  ZoneModel _emptyZone(String id) => ZoneModel(
    id: id,
    name: 'Unknown Zone',
    moisture: 0,
    temperature: 0,
    humidity: 0,
    dryingRate: 0,
    timeToStress: 0,
    stressScore: 0,
    recommendation: 'Calibration Pending',
    aiConfidence: 0,
  );

  Widget _buildStressHero(ZoneModel zone) {
    final healthScore = (100 - zone.stressScore).toInt();
    
    return FadeInDown(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [BoxShadow(color: AppColors.navyDeep.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Text('A-${zone.id} VITALITY INDEX', 
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                // Circular Glow Ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandEmerald.withAlpha(20),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: healthScore / 100,
                    strokeWidth: 16,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandEmerald),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text('$healthScore', 
                      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.navyDeep, height: 1)),
                    const Text('OPTIMAL', 
                      style: TextStyle(color: AppColors.brandEmerald, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(zone.recommendation, 
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(ZoneModel zone) {
    return Column(
      children: [
        Row(
          children: [
            _sensorTile('Soil Saturation', '${zone.moisture.toStringAsFixed(1)}%', LucideIcons.droplets, AppColors.waterMid),
            const SizedBox(width: 16),
            _sensorTile('Ambient Temp', '${zone.temperature.toStringAsFixed(1)}°C', LucideIcons.thermometer, AppColors.goldMid),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _sensorTile('Relative Humidity', '${zone.humidity.toStringAsFixed(0)}%', LucideIcons.cloud, AppColors.brandEmerald),
            const SizedBox(width: 16),
            _sensorTile('Node Capacity', '${zone.batteryLevel.toStringAsFixed(0)}%', 
              zone.batteryLevel < 20 ? LucideIcons.batteryLow : LucideIcons.battery, 
              zone.batteryLevel < 20 ? AppColors.danger : AppColors.brandEmerald),
          ],
        ),
      ],
    );
  }

  Widget _sensorTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border(top: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: AppColors.navyDeep.withAlpha(3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navyDeep)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporalIntelligence(ZoneModel zone) {
    final dryingRate = zone.dryingRate > 0 ? zone.dryingRate : 1.8;
    final timeToStress = zone.timeToStress > 0 ? zone.timeToStress : 4.2;
    final isUrgent = timeToStress < 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI PREDICTIVE TIMELINE',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.navyDeep, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _predictiveCard('EVAPORATION RATE', '${dryingRate.toStringAsFixed(1)}%/h', LucideIcons.trendingDown, AppColors.waterMid),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _predictiveCard('STRESS WINDOW', '${timeToStress.toStringAsFixed(1)}h', LucideIcons.clock, isUrgent ? AppColors.danger : AppColors.goldMid),
            ),
          ],
        ),
      ],
    );
  }

  Widget _predictiveCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 20),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildAdvancedTelemetryList(ZoneModel zone) {
    final items = [
      {'label': 'Solar Efficiency', 'value': '${zone.solarOutput.toStringAsFixed(1)}V', 'icon': LucideIcons.sun, 'color': AppColors.goldMid},
      {'label': 'Master Gateway', 'value': 'Connected', 'icon': LucideIcons.radio, 'color': AppColors.brandEmerald},
      {'label': 'Packet RSSI', 'value': '-84 dBm', 'icon': LucideIcons.signal, 'color': AppColors.brandEmerald},
    ];

    return Column(
      children: items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (item['color'] as Color).withAlpha(15), borderRadius: BorderRadius.circular(14)),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
            ),
            const SizedBox(width: 20),
            Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navyDeep)),
            const Spacer(),
            Text(item['value'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.brandEmerald)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMoistureTrend(ZoneModel zone) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: AppColors.navyDeep.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('MOISTURE INTEL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white, letterSpacing: 1.5)),
              const Spacer(),
              _legendDot(AppColors.brandEmerald, 'HISTORY'),
              const SizedBox(width: 16),
              _legendDot(AppColors.goldMid, 'PREDICTION', dashed: true),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withAlpha(20), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, meta) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.white38)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                    const labels = ['6h', '4h', '2h', 'Now', '+2h', '+4h'];
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Text(labels[i], style: const TextStyle(fontSize: 10, color: Colors.white38));
                  })),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 5, minY: 20, maxY: 65,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 50), FlSpot(1, 48), FlSpot(2, 44), FlSpot(3, 40)],
                    isCurved: true,
                    color: AppColors.brandEmerald,
                    barWidth: 4,
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.brandEmerald.withAlpha(40), AppColors.brandEmerald.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                  LineChartBarData(
                    spots: const [FlSpot(3, 40), FlSpot(4, 34), FlSpot(5, 28)],
                    isCurved: true,
                    color: AppColors.goldMid,
                    barWidth: 3,
                    dashArray: [8, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildPlantStageLink(BuildContext context, ZoneModel zone) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.aiAdvisoryGradient),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(LucideIcons.leaf, color: AppColors.brandEmerald, size: 24),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLANT PHENOLOGY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                SizedBox(height: 6),
                Text('View root development & stage info', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ZoneModel zone) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            try {
              await ApiService().triggerIrrigation(zone.id, 15);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Precision Irrigation Triggered.')));
                ref.read(farmProvider.notifier).refresh();
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Command Failed: $e')));
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 72),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.growthGradient),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.brandEmerald.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Container(
              alignment: Alignment.center,
              child: const Text('ENGAGE IRRIGATION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
            ),
          ),
        ),
      ],
    );
  }
}
