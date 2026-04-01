import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/models/zone_model.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';

class _Alert {
  final String tag, title, desc, time;
  final Color color;
  final IconData icon;
  const _Alert({
    required this.tag, required this.title, required this.desc,
    required this.color, required this.icon, required this.time,
  });
}

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        farmAsync.when(
          data: (farm) {
            final zones = farm.acres.expand((a) => a.zones).toList();
            final alerts = _buildAlerts(zones);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Alerts Center',
                      style: Theme.of(context).textTheme.displaySmall),
                  Text('${alerts.length} active notifications from ${farm.name}.',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  if (alerts.isEmpty)
                    _buildEmptyState()
                  else
                    ...alerts.asMap().entries.map((entry) => FadeInUp(
                      delay: Duration(milliseconds: entry.key * 80),
                      child: _AlertCard(alert: entry.value),
                    )),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Sync Error: $e")),
        ),
        const GlassNav(currentPath: '/alerts'),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Column(children: [
      const SizedBox(height: 100),
      const Icon(LucideIcons.checkCircle2, color: AppColors.emerald, size: 64),
      const SizedBox(height: 20),
      const Text('All systems normal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const Text('No critical alerts for your farm at this time.', style: TextStyle(color: AppColors.textSecondary)),
    ]);
  }

  List<_Alert> _buildAlerts(List<ZoneModel> zones) {
    final list = <_Alert>[];

    for (final z in zones) {
      if (z.status == 'Critical') {
        list.add(_Alert(
          tag:   'CRITICAL',
          title: 'Zone ${z.id}: Extreme Moisture Stress',
          desc:  'Current moisture (${z.moisture.toStringAsFixed(1)}%) is below '
                 'threshold. Immediate irrigation required. ${z.recommendation}.',
          color: AppColors.danger,
          icon:  LucideIcons.alertOctagon,
          time:  'Live',
        ));
      } else if (z.status == 'Warning') {
        list.add(_Alert(
          tag:   'AI PREDICTION',
          title: 'Zone ${z.id}: Stress Forecast',
          desc:  'Moisture trending to stress in '
                 '${z.timeToStress.toStringAsFixed(1)} hrs at '
                 '${z.dryingRate.toStringAsFixed(2)}%/hr. Aura recommends proactive action.',
          color: AppColors.warning,
          icon:  LucideIcons.brain,
          time:  'Predictive',
        ));
      }
    }

    if (zones.isNotEmpty) {
      list.add(_Alert(
        tag:   'SYSTEM',
        title: 'Network Optimized',
        desc:  'Local IoT gateway is currently using edge reasoning to minimize latency.',
        color: AppColors.info,
        icon:  LucideIcons.wifi,
        time:  'Now',
      ));
    }

    return list;
  }
}

class _AlertCard extends StatelessWidget {
  final _Alert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alert.color.withAlpha(60)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: alert.color.withAlpha(26),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(alert.tag,
                style: TextStyle(color: alert.color,
                    fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
          ),
          Text(alert.time,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(alert.icon, color: alert.color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(alert.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ]),
        const SizedBox(height: 9),
        Text(alert.desc,
            style: const TextStyle(color: AppColors.textSecondary,
                fontSize: 13, height: 1.5)),
      ]),
    );
  }
}
