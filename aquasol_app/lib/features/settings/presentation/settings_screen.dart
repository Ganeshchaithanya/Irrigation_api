import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';
import 'package:aquasol_app/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.get('Settings', lang), style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _buildProfileCard(ref),
            const SizedBox(height: 32),
            _buildSection(AppLocalizations.get('Localization', lang), [
              _buildLanguageTile(ref, lang),
              _buildSettingTile(
                'Units', 
                'Metric (Celsius, Hectares)', 
                LucideIcons.gauge, 
                () => _showComingSoon(context),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSection(AppLocalizations.get('Security', lang), [
              _buildSettingTile(
                'Notification Alerts', 
                'Critical irrigation warnings', 
                LucideIcons.bell, 
                () => _showComingSoon(context),
              ),
              _buildSettingTile(
                'Account Security', 
                'Manage phone authentication', 
                LucideIcons.lock, 
                () => _showComingSoon(context),
              ),
            ]),
            const SizedBox(height: 48),
            _buildLogoutButton(context, ref, lang),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.emerald.withAlpha(20),
            child: const Icon(LucideIcons.user, color: AppColors.emerald, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AquaSol Farmer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(auth.userId ?? 'Demo Account', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: AppColors.textMuted, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildLanguageTile(WidgetRef ref, String currentLang) {
    return ListTile(
      leading: const Icon(LucideIcons.languages, color: AppColors.emerald),
      title: const Text('App Language', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(currentLang, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: () => _showLanguagePicker(ref),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, String lang) {
    return FadeInUp(
      child: OutlinedButton(
        onPressed: () {
          ref.read(authProvider.notifier).logout();
          context.go('/auth');
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          side: const BorderSide(color: AppColors.danger, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          foregroundColor: AppColors.danger,
        ),
        child: const Text('Logout Session', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _showLanguagePicker(WidgetRef ref) {
    // Basic language toggle for demo, or show a bottom sheet
    final current = ref.read(languageProvider);
    final next = current == 'English' ? 'Hindi' : (current == 'Hindi' ? 'Telugu' : 'English');
    ref.read(languageProvider.notifier).setLanguage(next);
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This feature is being tuned for your region.')));
  }
}
