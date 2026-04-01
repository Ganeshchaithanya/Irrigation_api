import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';

// ── Stage definitions with AI water-demand multipliers ────────────────────────
const _stages = [
  {
    'title': 'Germination',
    'date': 'Completed',
    'status': 'done',
    'multiplier': 1.2,
    'days': 0,
  },
  {
    'title': 'Vegetative',
    'date': 'Active Now (Day 24)',
    'status': 'current',
    'multiplier': 1.5,
    'days': 0,
  },
  {
    'title': 'Flowering',
    'date': 'Est. in 12 days',
    'status': 'upcoming',
    'multiplier': 1.8,
    'days': 12,
  },
  {
    'title': 'Harvesting',
    'date': 'Est. in 45 days',
    'status': 'upcoming',
    'multiplier': 0.8,
    'days': 45,
  },
];

class PlantStageScreen extends ConsumerWidget {
  final String zoneId;
  const PlantStageScreen({super.key, required this.zoneId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current and next stage for AI prediction message
    final currentIdx = _stages.indexWhere((s) => s['status'] == 'current');
    final next = currentIdx >= 0 && currentIdx < _stages.length - 1
        ? _stages[currentIdx + 1]
        : null;
    final currentMultiplier = currentIdx >= 0
        ? (_stages[currentIdx]['multiplier'] as double)
        : 1.0;
    final nextMultiplier = next != null ? (next['multiplier'] as double) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plant Growth Stage', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeInUp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDailyIrrigationCard(currentMultiplier),
              const SizedBox(height: 16),
              if (next != null && nextMultiplier != null)
                _buildAIPredictionBanner(next, currentMultiplier, nextMultiplier),
              const SizedBox(height: 32),
              const Text('Growth Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              _buildTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyIrrigationCard(double multiplier) {
    final baseLiters = 233.0;
    final adjusted = (baseLiters * multiplier).round();
    final baseMm = 9.4;
    final adjustedMm = (baseMm * multiplier).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.info,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.info.withAlpha(50), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(LucideIcons.droplets, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text("Today's Irrigation",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          Text('$adjustedMm mm',
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
          Text('~$adjusted Liters consumed (${multiplier}x stage factor)',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAIPredictionBanner(
      Map<String, Object> next, double currentMx, double nextMx) {
    final increase = (((nextMx - currentMx) / currentMx) * 100).round();
    final daysAway = next['days'] as int;
    final nextTitle = next['title'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.trendingUp, color: AppColors.warning, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Stage Prediction',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'Water demand will increase by $increase% in $daysAway days ($nextTitle stage, ${nextMx}x multiplier).',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: _stages.asMap().entries.map((e) {
        final isLast = e.key == _stages.length - 1;
        final stage = e.value;
        return _timelineItem(
          stage['title'] as String,
          stage['date'] as String,
          stage['status'] as String,
          stage['multiplier'] as double,
          !isLast,
        );
      }).toList(),
    );
  }

  Widget _timelineItem(
      String title, String date, String status, double multiplier, bool hasLine) {
    Color dotColor = AppColors.borderLight;
    Color lineCol = AppColors.borderLight;
    if (status == 'done') {
      dotColor = AppColors.emerald;
      lineCol = AppColors.emerald;
    } else if (status == 'current') {
      dotColor = AppColors.info;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: (status == 'current' || status == 'done')
                    ? dotColor
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 3),
              ),
            ),
            if (hasLine) Container(width: 3, height: 70, color: lineCol),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: status == 'current' ? FontWeight.w900 : FontWeight.w600,
                      color: status == 'upcoming'
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'current'
                          ? AppColors.info.withAlpha(20)
                          : AppColors.borderLight.withAlpha(80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${multiplier}x water',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'current'
                            ? AppColors.info
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: status == 'current'
                      ? AppColors.info
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
