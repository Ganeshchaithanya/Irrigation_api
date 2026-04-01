import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';

class AiDecisionScreen extends ConsumerWidget {
  const AiDecisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeader(context),
              _buildReasoningEngine(),
              _buildTelemetryFeed(),
              _buildConfidenceMeter(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          const GlassNav(currentPath: '/decisions'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.brainCircuit, color: AppColors.emerald, size: 28),
                const SizedBox(width: 12),
                Text('Aura Decision Engine', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Transparent reasoning for every irrigation event.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningEngine() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Reasoning Flow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              _reasoningStep(1, 'Data Ingestion', 'Fetched moisture levels from 12 IoT nodes.', true),
              _reasoningStep(2, 'Anomaly Detection', 'Detected 15% faster drying in Zone A2.', true),
              _reasoningStep(3, 'Weather Overlay', 'Cloudy skies expected; adjusted threshold by -5%.', true),
              _reasoningStep(4, 'Optimization', 'Consolidating Zone A2 and B1 irrigation to save pump power.', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reasoningStep(int num, String title, String desc, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: done ? AppColors.emerald : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done 
                ? const Icon(LucideIcons.check, color: Colors.white, size: 14)
                : Text('$num', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: done ? AppColors.textPrimary : AppColors.textSecondary)),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryFeed() {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backend Telemetry Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'INFO: [Aura] Analyzing moisture_gradient Vector(0.42, 0.88)\n'
                'DEBUG: threshold reached at 0.12s\n'
                'ACTION: valve_trigger_request (zone: 4)\n'
                'SUCCESS: backend_response_code 200',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceMeter() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              Text('Model Confidence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 12),
              Text('98.4%', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('High precision based on 4,200 data points.', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
