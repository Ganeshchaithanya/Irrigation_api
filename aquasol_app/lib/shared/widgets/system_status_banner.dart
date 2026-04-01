import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquasol_app/providers/system_status_provider.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';

class SystemStatusBanner extends ConsumerWidget {
  const SystemStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(systemStatusProvider);

    final Color bgColor;
    final Color textColor;
    final IconData icon;

    switch (status.status) {
      case SystemStatus.aiActive:
        bgColor = AppColors.warning;
        textColor = Colors.white;
        icon = Icons.electric_bolt_rounded;
        break;
      case SystemStatus.warning:
        bgColor = Colors.orange.shade700;
        textColor = Colors.white;
        icon = Icons.warning_amber_rounded;
        break;
      case SystemStatus.offline:
        bgColor = Colors.grey.shade700;
        textColor = Colors.white;
        icon = Icons.wifi_off_rounded;
        break;
      case SystemStatus.success:
        bgColor = Colors.blue.shade700;
        textColor = Colors.white;
        icon = Icons.insights_rounded;
        break;
      case SystemStatus.stable:
        bgColor = AppColors.emerald;
        textColor = Colors.white;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 8),
          Text(
            status.message,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
