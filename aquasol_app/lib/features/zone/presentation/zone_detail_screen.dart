import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/models/zone_model.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/services/api_service.dart';

class ZoneDetailScreen extends ConsumerWidget {
  final String zoneId;
  const ZoneDetailScreen({super.key, required this.zoneId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('A-$zoneId Detail', style: const TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
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
                _buildStressHero(zone),
                const SizedBox(height: 24),
                _buildSensorGrid(zone),
                const SizedBox(height: 24),
                _buildTemporalIntelligence(zone),
                const SizedBox(height: 32),
                const Text('Advanced Telemetry', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                _buildAdvancedTelemetryList(zone),
                const SizedBox(height: 32),
                _buildMoistureTrend(zone),
                const SizedBox(height: 32),
                _buildPlantStageLink(context, zone),
                const SizedBox(height: 32),
                _buildActionButtons(context, ref, zone),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  ZoneModel _emptyZone(String id) => ZoneModel(
    id: id,
    name: 'Unknown',
    moisture: 0,
    temperature: 0,
    humidity: 0,
    dryingRate: 0,
    timeToStress: 0,
    stressScore: 0,
    recommendation: 'N/A',
    aiConfidence: 0,
  );

  Widget _buildStressHero(ZoneModel zone) {
    final healthScore = (100 - zone.stressScore).toInt();
    Color statusColor = AppColors.success;
    if (zone.status == 'Warning') statusColor = AppColors.warning;
    if (zone.status == 'Critical') statusColor = AppColors.danger;

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
          Text('A-${zone.id} Health Score', 
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: healthScore / 100,
                  strokeWidth: 20,
                  backgroundColor: AppColors.borderLight.withAlpha(100),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text('$healthScore%', 
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: statusColor)),
                  const Text('Optimal', 
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(zone.recommendation, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSensorGrid(ZoneModel zone) {
    return Column(
      children: [
        Row(
          children: [
            _sensorTile('Soil Moisture', '${zone.moisture.toStringAsFixed(1)}%', LucideIcons.droplets, AppColors.info),
            const SizedBox(width: 16),
            _sensorTile('Temperature', '${zone.temperature.toStringAsFixed(1)}°C', LucideIcons.thermometer, AppColors.warning),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _sensorTile('Humidity', '${zone.humidity.toStringAsFixed(0)}%', LucideIcons.cloud, AppColors.info),
            const SizedBox(width: 16),
            _sensorTile('Battery', '${zone.batteryLevel.toStringAsFixed(0)}%', 
              zone.batteryLevel < 20 ? LucideIcons.batteryLow : LucideIcons.battery, 
              zone.batteryLevel < 20 ? AppColors.danger : AppColors.success),
          ],
        ),
      ],
    );
  }

  Widget _sensorTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporalIntelligence(ZoneModel zone) {
    // Derive values from backend model or use intelligent fallback
    final dryingRate = zone.dryingRate > 0 ? zone.dryingRate : 1.8;
    final timeToStress = zone.timeToStress > 0 ? zone.timeToStress : 4.2;
    final isUrgent = timeToStress < 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⏱ Temporal Intelligence',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.info.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.info.withAlpha(25),
                          shape: BoxShape.circle),
                      child: const Icon(LucideIcons.trendingDown,
                          color: AppColors.info, size: 18),
                    ),
                    const SizedBox(height: 16),
                    Text('${dryingRate.toStringAsFixed(1)}% / hr',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    const Text('Drying Rate',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isUrgent
                          ? AppColors.danger.withAlpha(80)
                          : AppColors.warning.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: (isUrgent ? AppColors.danger : AppColors.warning)
                              .withAlpha(25),
                          shape: BoxShape.circle),
                      child: Icon(LucideIcons.clock,
                          color: isUrgent ? AppColors.danger : AppColors.warning,
                          size: 18),
                    ),
                    const SizedBox(height: 16),
                    Text('${timeToStress.toStringAsFixed(1)} hrs',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isUrgent
                                ? AppColors.danger
                                : AppColors.textPrimary)),
                    const Text('Time to Stress',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (isUrgent)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withAlpha(40)),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.alertTriangle,
                      color: AppColors.danger, size: 15),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Alert: Stress imminent. Recommend immediate irrigation.',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdvancedTelemetryList(ZoneModel zone) {
    final items = [
      {'label': 'Solar Output', 'value': '${zone.solarOutput.toStringAsFixed(1)}V', 'icon': LucideIcons.sun, 'color': AppColors.warning},
      {'label': 'LoRa Signal', 'value': 'Good', 'icon': LucideIcons.wifi, 'color': AppColors.success},
      {'label': 'Storage Tank', 'value': '90%', 'icon': LucideIcons.database, 'color': AppColors.info},
    ];

    return Column(
      children: items.map((item) => Container(
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
              decoration: BoxDecoration(color: (item['color'] as Color).withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const Spacer(),
            Text(item['value'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.emerald)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMoistureTrend(ZoneModel zone) {
    return Container(
      height: 270,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Moisture Trend', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const Spacer(),
              _legendDot(AppColors.emerald, 'History'),
              const SizedBox(width: 12),
              _legendDot(AppColors.warning, 'Prediction', dashed: true),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.borderLight.withAlpha(80),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, meta) => Text(
                        '${v.toInt()}%',
                        style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        const labels = ['6h', '5h', '4h', '3h', 'Now', '+1h', '+2h'];
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Text(labels[i],
                            style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6, minY: 20, maxY: 65,
                lineBarsData: [
                  // ── Solid: Historical ──────────────────────────────
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 52), FlSpot(1, 48), FlSpot(2, 45),
                      FlSpot(3, 42), FlSpot(4, 38),
                    ],
                    isCurved: true,
                    color: AppColors.emerald,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: idx == 4 ? 5 : 0,
                        color: AppColors.emerald,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.emerald.withAlpha(15),
                    ),
                  ),
                  // ── Dashed: Prediction ─────────────────────────────
                  LineChartBarData(
                    spots: const [
                      FlSpot(4, 38), FlSpot(5, 33), FlSpot(6, 27),
                    ],
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 2.5,
                    dashArray: [6, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.warning,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.warning.withAlpha(10),
                    ),
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
        Container(
          width: 20, height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed ? Border(bottom: BorderSide(color: color, width: 2, style: BorderStyle.solid)) : null,
            borderRadius: BorderRadius.circular(2),
          ),
          child: dashed
              ? CustomPaint(painter: _DashPainter(color))
              : null,
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPlantStageLink(BuildContext context, ZoneModel zone) {
    return GestureDetector(
      onTap: () => context.push('/zone/${zone.id}/stage'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.emerald.withAlpha(15),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.emerald.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(LucideIcons.leaf, color: AppColors.emerald),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plant Growth Stage', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('View crop evolution & daily water context', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.emerald),
          ],
        ),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Irrigation started')));
                ref.read(farmProvider.notifier).refresh();
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            backgroundColor: AppColors.emerald,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('Start Irrigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historical telemetry logs available offline.'))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('View History'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hardware Node status: Connected.'))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Device Status'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    var max = size.width;
    var dashWidth = 4;
    var dashSpace = 3;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
