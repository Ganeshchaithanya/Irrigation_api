import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';

class GlassNav extends ConsumerWidget {
  final String currentPath;
  const GlassNav({super.key, required this.currentPath});

  static const _items = [
    (icon: LucideIcons.home,          path: '/dashboard', label: 'Home'),
    (icon: LucideIcons.layoutGrid,    path: '/farm',      label: 'Farm'),
    (icon: LucideIcons.sliders,       path: '/irrigation', label: 'Control'),
    (icon: LucideIcons.barChart,      path: '/analytics',  label: 'Analytics'),
    (icon: LucideIcons.messageCircle, path: '/chat',       label: 'Chat'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235), // Nearly solid white for readability
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(color: AppColors.borderLight, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _items
              .map((item) => _NavItem(
                    icon: item.icon,
                    label: AppLocalizations.get(item.label, lang),
                    path: item.path,
                    isActive: currentPath == item.path,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.emerald.withAlpha(20) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.emerald : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? AppColors.emerald : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

