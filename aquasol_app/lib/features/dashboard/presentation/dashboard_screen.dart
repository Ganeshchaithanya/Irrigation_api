import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/models/farm_model.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';
import 'package:aquasol_app/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';
import 'package:aquasol_app/shared/widgets/system_status_banner.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider);
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              const SafeArea(bottom: false, child: SystemStatusBanner()),
              Expanded(
                child: farmAsync.when(
                  data: (farm) => _buildContent(context, farm, ref, currentLanguage),
                  loading: () => _buildLoadingState(context),
                  error: (e, st) => _buildErrorState(context, e, ref),
                ),
              ),
            ],
          ),
          const GlassNav(currentPath: '/dashboard'),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref, String currentLanguage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(top: 24, bottom: 40, left: 24, right: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.get('Select Language', currentLanguage), style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(AppLocalizations.get('Choose your preferred language for Aura AI insights and application text.', currentLanguage),
              style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ...supportedLanguages.map((lang) {
              final isSelected = lang == currentLanguage;
              return ListTile(
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage(lang);
                  Navigator.pop(context);
                },
                leading: Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  color: isSelected ? AppColors.emerald : AppColors.textMuted,
                ),
                title: Text(
                  lang,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.emerald : AppColors.textPrimary,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FarmModel farm, WidgetRef ref, String currentLanguage) {
    final zones = farm.acres.expand((a) => a.zones).toList();
    // Derived stats for high-fidelity UI
    final avgStress = zones.isEmpty ? 0.0 : zones.map((z) => z.stressScore).reduce((a, b) => a + b) / zones.length;
    final healthScore = ((100 - avgStress) / 10).toStringAsFixed(1);
    final temp = zones.isNotEmpty ? zones.first.temperature.toString() : "28"; // Fallback to 28C if no data
    final waterUsed = 3200; // Placeholder for weekly analytics

    return RefreshIndicator(
      onRefresh: () => ref.read(farmProvider.notifier).refresh(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            _buildHeader(context, ref, farm.name, currentLanguage),
            _buildFeatureCarousel(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHealthHero(healthScore, zones.length, currentLanguage),
                  const SizedBox(height: 20),
                  _buildQuickStats(temp, "0%", "${waterUsed}L", currentLanguage),
                  const SizedBox(height: 24),
                  _buildAiAdvisory(
                    currentLanguage, 
                    zones.isNotEmpty ? zones.first.recommendation : "Healthy"
                  ),
                  const SizedBox(height: 24),
                  _buildQuickAccess(context, currentLanguage),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String name, String currentLanguage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.get('Good Morning', currentLanguage), 
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(name.split(' ').first, 
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showLanguageSelector(context, ref, currentLanguage),
                child: _headerIcon(LucideIcons.globe),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showNotificationCenter(context, ref, currentLanguage),
                child: _headerIcon(
                  LucideIcons.bell, 
                  hasBadge: ref.watch(notificationProvider).any((n) => !n.isRead),
                  badgeCount: ref.watch(notificationProvider).where((n) => !n.isRead).length,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: _headerIcon(LucideIcons.user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, {bool hasBadge = false, int badgeCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
        if (hasBadge)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationCenter(BuildContext context, WidgetRef ref, String lang) {
    final notifications = ref.watch(notificationProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.get('Notifications', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  TextButton(
                    onPressed: () => ref.read(notificationProvider.notifier).clearAll(),
                    child: Text(AppLocalizations.get('Clear All', lang), style: const TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? Center(child: Text(AppLocalizations.get('No Notifications', lang), style: const TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: notifications.length,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemBuilder: (context, i) {
                        final n = notifications[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: n.isRead ? Colors.white.withAlpha(150) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: n.isRead ? Colors.transparent : AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: n.type == 'alert' ? AppColors.danger.withAlpha(20) : AppColors.info.withAlpha(20),
                                child: Icon(
                                  n.type == 'alert' ? LucideIcons.alertTriangle : LucideIcons.info,
                                  color: n.type == 'alert' ? AppColors.danger : AppColors.info,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.bold : FontWeight.w900, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(n.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('hh:mm a').format(n.timestamp), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (!n.isRead)
                                IconButton(
                                  icon: const Icon(LucideIcons.check, size: 16),
                                  onPressed: () => ref.read(notificationProvider.notifier).markAsRead(n.id),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCarousel() {
    final features = [
      {'title': 'Aura AI Insights', 'desc': 'Real-time crop stress prediction active', 'icon': LucideIcons.sparkles},
      {'title': 'Precision Mapping', 'desc': 'Interactive farm layout grid is live', 'icon': LucideIcons.map},
      {'title': 'Smarter Irrigation', 'desc': 'New scheduling presets available', 'icon': LucideIcons.droplets},
    ];

    return SizedBox(
      height: 100,
      child: Swiper(
        itemCount: features.length,
        viewportFraction: 0.88,
        scale: 0.95,
        autoplay: true,
        autoplayDelay: 4500,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.emerald.withAlpha(20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.emerald.withAlpha(40), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(features[i]['icon'] as IconData, color: AppColors.emerald, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(features[i]['title'] as String, 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2)),
                    Text(features[i]['desc'] as String, 
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthHero(String score, int zones, String lang) {
    return FadeInUp(
      child: Container(
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
            BoxShadow(
              color: AppColors.emerald.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.get('Farm Health Score', lang), 
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(AppLocalizations.get('Healthy', lang), 
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(score, style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900)),
                Text(' /10', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.activity, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text('$zones ${AppLocalizations.get('zones active', lang)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(String temp, String rain, String water, String lang) {
    return Row(
      children: [
        _statCard('$temp°C', AppLocalizations.get('Temperature', lang), LucideIcons.thermometer),
        const SizedBox(width: 12),
        _statCard(rain, AppLocalizations.get('Rain Today', lang), LucideIcons.cloudRain),
        const SizedBox(width: 12),
        _statCard(water, AppLocalizations.get('Water Usage', lang), LucideIcons.droplets),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
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
            Icon(icon, color: AppColors.warning, size: 24),
            const SizedBox(height: 24),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAdvisory(String lang, String recommendation) {
    return FadeInUp(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.aiAdvisoryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.get('AI Crop Advisory', lang), 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(recommendation, 
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.get('Quick Access', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            TextButton(
              onPressed: () => context.go('/farm'),
              child: const Text('View All', 
                style: TextStyle(color: AppColors.emerald, fontSize: 13, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickCard(AppLocalizations.get('Crop Guide', lang), LucideIcons.scroll, () => context.push('/planner')),
            const SizedBox(width: 12),
            _quickCard(AppLocalizations.get('Farm Diary', lang), LucideIcons.bookOpen, () => context.push('/diary')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickCard(AppLocalizations.get('Advanced', lang), LucideIcons.settings, () => context.push('/analytics')),
            const SizedBox(width: 12),
            _quickCard(AppLocalizations.get('Settings', lang), LucideIcons.sliders, () => context.push('/settings')),
          ],
        ),
      ],
    );
  }

  Widget _quickCard(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.emerald, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(height: 100, margin: const EdgeInsets.all(20), color: Colors.white),
          Container(height: 180, margin: const EdgeInsets.symmetric(horizontal: 20), color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object e, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text('Sync Failed: $e', style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: () => ref.read(farmProvider.notifier).refresh(), child: const Text('Retry Sync')),
        ],
      ),
    );
  }
}
