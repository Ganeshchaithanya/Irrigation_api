import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/models/farm_model.dart';
import 'package:aquasol_app/models/zone_model.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';

class FarmScreen extends ConsumerWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          farmAsync.when(
            data: (farm) => _buildContent(context, farm),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Sync failed: $e")),
          ),
          const GlassNav(currentPath: '/farm'),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, FarmModel farm) {
    final allZones = farm.acres.expand((a) => a.zones).toList();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          _buildHeader(farm.location),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFarmLayoutGrid(context, allZones),
                const SizedBox(height: 32),
                const Text('All Zones', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                _buildZonesList(context, farm),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String location) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(location, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('My Farm', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildFarmLayoutGrid(BuildContext context, List<ZoneModel> zones) {
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
          const Text('FARM LAYOUT', 
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4, // As per Image 3 (A-1 to A-4)
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, i) {
              final zone = zones.length > i ? zones[i] : null;
              final String id = 'A-${i + 1}';
              
              // Status Logic to match Image 3
              String status = 'Healthy';
              Color color = AppColors.success;
              if (i == 1) { status = 'Warning'; color = AppColors.warning; }
              if (i == 2) { status = 'Irrigating'; color = AppColors.info; }

              return _layoutCard(context, id, zone?.moisture.toStringAsFixed(1) ?? "--", status, color, zone?.id);
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Healthy', AppColors.success),
              const SizedBox(width: 16),
              _legendItem('Warning', AppColors.warning),
              const SizedBox(width: 16),
              _legendItem('Irrigating', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _layoutCard(BuildContext context, String id, String moisture, String status, Color color, String? realId) {
    return GestureDetector(
      onTap: () { if (realId != null) context.push('/zone/$realId'); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(30), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Icon(LucideIcons.activity, size: 14, color: color),
              ],
            ),
            const Spacer(),
            Text(moisture, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text(status, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildZonesList(BuildContext context, FarmModel farm) {
    final List<Widget> items = [];
    
    for (var i = 0; i < farm.acres.length; i++) {
      final acre = farm.acres[i];
      for (var zone in acre.zones) {
        items.add(
          FadeInUp(
            delay: Duration(milliseconds: items.length * 80),
            child: GestureDetector(
              onTap: () => context.push('/zone/${zone.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acre ${i + 1} — ${acre.cropType}', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(zone.name, 
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            _statusChip(zone.status),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(zone.moisture.toStringAsFixed(1), 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text('Health', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return Column(children: items);
  }

  Widget _statusChip(String status) {
    Color c = AppColors.success;
    if (status == 'Warning') c = AppColors.warning;
    if (status == 'Critical') c = AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status.toLowerCase(), 
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
