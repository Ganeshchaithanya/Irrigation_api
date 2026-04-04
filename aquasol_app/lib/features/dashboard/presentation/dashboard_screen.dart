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
import 'package:flutter_animate/flutter_animate.dart';

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
          // Background subtle blob
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandEmerald.withAlpha(10),
              ),
            ),
          ),
          
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
            Text(AppLocalizations.get('Select Language', currentLanguage), 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navyDeep)),
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
                  color: isSelected ? AppColors.brandEmerald : AppColors.textMuted,
                ),
                title: Text(
                  lang,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.brandEmerald : AppColors.textPrimary,
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
    final avgStress = zones.isEmpty ? 0.0 : zones.map((z) => z.stressScore).reduce((a, b) => a + b) / zones.length;
    final healthScore = ((100 - avgStress) / 10).toStringAsFixed(1);
    final temp = zones.isNotEmpty ? zones.first.temperature.toString() : "28"; 

    return RefreshIndicator(
      onRefresh: () => ref.read(farmProvider.notifier).refresh(),
      color: AppColors.brandEmerald,
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
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: _buildHealthHero(healthScore, zones.length, currentLanguage),
                  ),
                  const SizedBox(height: 24),
                  _buildQuickStats(
                    temp, 
                    zones.isNotEmpty && zones.first.isRaining ? "Raining" : "Standard", 
                    "${zones.isNotEmpty ? zones.first.currentFlow.toStringAsFixed(1) : '0'} L/m", 
                    currentLanguage
                  ),
                  const SizedBox(height: 24),
                  _buildAiAdvisory(
                    currentLanguage, 
                    zones.isNotEmpty ? zones.first.recommendation : "System Nominal"
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
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.brandEmerald, shape: BoxShape.circle),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fadeOut(duration: 800.ms),
                  const SizedBox(width: 8),
                  Text('LIVE TELEMETRY', 
                    style: TextStyle(color: AppColors.brandEmerald.withAlpha(200), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 4),
              Text(name.split(' ').first, 
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.navyDeep, letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              _headerIcon(context, LucideIcons.globe, onTap: () => _showLanguageSelector(context, ref, currentLanguage)),
              const SizedBox(width: 12),
              _headerIcon(
                context, 
                LucideIcons.bell, 
                onTap: () => _showNotificationCenter(context, ref, currentLanguage),
                hasBadge: ref.watch(notificationProvider).any((n) => !n.isRead),
                badgeCount: ref.watch(notificationProvider).where((n) => !n.isRead).length,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(BuildContext context, IconData icon, {required VoidCallback onTap, bool hasBadge = false, int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [BoxShadow(color: AppColors.navyDeep.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, size: 22, color: AppColors.navyDeep),
          ),
          if (hasBadge)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotificationCenter(BuildContext context, WidgetRef ref, String lang) {
    final notifications = ref.watch(notificationProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.get('Notifications', lang), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navyDeep)),
                  TextButton(
                    onPressed: () => ref.read(notificationProvider.notifier).clearAll(),
                    child: Text(AppLocalizations.get('Clear All', lang), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? Center(child: Text(AppLocalizations.get('No Notifications', lang), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)))
                  : ListView.builder(
                      itemCount: notifications.length,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemBuilder: (context, i) {
                        final n = notifications[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: n.isRead ? Colors.white.withAlpha(160) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: n.isRead ? Colors.transparent : AppColors.borderLight),
                            boxShadow: n.isRead ? [] : [BoxShadow(color: AppColors.navyDeep.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: n.type == 'alert' ? AppColors.danger.withAlpha(15) : AppColors.info.withAlpha(15),
                                child: Icon(
                                  n.type == 'alert' ? LucideIcons.alertTriangle : LucideIcons.info,
                                  color: n.type == 'alert' ? AppColors.danger : AppColors.info,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900, fontSize: 15, color: AppColors.navyDeep)),
                                    const SizedBox(height: 6),
                                    Text(n.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3)),
                                    const SizedBox(height: 8),
                                    Text(DateFormat('hh:mm a').format(n.timestamp), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
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
      {'title': 'Aura AI Monitoring', 'desc': 'Real-time crop stress analysis active', 'icon': LucideIcons.sparkles, 'color': AppColors.waterMid},
      {'title': 'Precision Topography', 'desc': 'S-M-E sensor mapping is live', 'icon': LucideIcons.map, 'color': AppColors.brandEmerald},
      {'title': 'Smart Irrigation', 'desc': 'Optimized watering cycles calculated', 'icon': LucideIcons.droplets, 'color': AppColors.goldMid},
    ];

    return SizedBox(
      height: 120,
      child: Swiper(
        itemCount: features.length,
        viewportFraction: 0.9,
        scale: 0.95,
        autoplay: true,
        autoplayDelay: 5000,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (features[i]['color'] as Color).withAlpha(10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: (features[i]['color'] as Color).withAlpha(30), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Icon(features[i]['icon'] as IconData, color: features[i]['color'] as Color, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(features[i]['title'] as String, 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.navyDeep)),
                    const SizedBox(height: 4),
                    Text(features[i]['desc'] as String, 
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.growthGradient,
          ),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandEmerald.withAlpha(50),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.get('FARM HEALTH SCORE', lang).toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                  child: Text(AppLocalizations.get('VIBRANT', lang), 
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(score, style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Text('/10', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 24, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(LucideIcons.activity, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('$zones ${AppLocalizations.get('Precision Zones Active', lang)}', 
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
        _statCard('$temp°C', AppLocalizations.get('Temperature', lang), LucideIcons.thermometer, AppColors.goldMid),
        const SizedBox(width: 12),
        _statCard(rain, AppLocalizations.get('Rain Intel', lang), LucideIcons.cloudRain, AppColors.waterMid),
        const SizedBox(width: 12),
        _statCard(water, AppLocalizations.get('Flow Rate', lang), LucideIcons.droplets, AppColors.brandEmerald),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [BoxShadow(color: AppColors.navyDeep.withAlpha(3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.navyDeep)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAdvisory(String lang, String recommendation) {
    return FadeInUp(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.aiAdvisoryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: AppColors.waterMid.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(18)),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.get('AI CROP ADVISORY', lang).toUpperCase(), 
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(recommendation, 
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
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
            Text(AppLocalizations.get('Ecosystem Control', lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navyDeep)),
            TextButton(
              onPressed: () => context.go('/farm'),
              child: const Text('View All', 
                style: TextStyle(color: AppColors.brandEmerald, fontSize: 14, fontWeight: FontWeight.w900))),
          ],
        ),
        const SizedBox(height: 16),
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
            _quickCard(AppLocalizations.get('Intelligence', lang), LucideIcons.brainCircuit, () => context.push('/analytics')),
            const SizedBox(width: 12),
            _quickCard(AppLocalizations.get('System Settings', lang), LucideIcons.sliders, () => context.push('/settings')),
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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [BoxShadow(color: AppColors.navyDeep.withAlpha(3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandEmerald, size: 22),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.navyDeep))),
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
          Text('Sync Failed: $e', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(farmProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('RETRY SYNC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
