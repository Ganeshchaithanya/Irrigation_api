import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';

import 'package:aquasol_app/providers/auth_provider.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Artificial delay for brand exposure
    await Future.delayed(const Duration(milliseconds: 3500));
    if (!mounted) return;
    
    final auth = ref.read(authProvider);
    
    // Check if user is logged in
    if (auth.userId == null) {
      context.go('/auth');
      return;
    }

    // Check if farm setup is likely complete by checking the backend sync state
    // (In a real app, we'd check if a farmId is associated with this userId)
    await ref.read(farmProvider.notifier).loadFarm(silent: true);
    if (!mounted) return;

    final farm = ref.read(farmProvider);
    if (farm.hasValue && farm.value != null) {
      context.go('/dashboard');
    } else {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.emeraldDark,
              Color(0xFF064E3B), // Extra dark emerald
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background subtle circles
            Positioned(
              top: -100,
              right: -100,
              child: FadeInDown(
                duration: const Duration(seconds: 2),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(12),
                  ),
                ),
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animation
                ZoomIn(
                  duration: const Duration(milliseconds: 1200),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Dynamically calculate size based on screen width (roughly 45%)
                      final double screenWidth = MediaQuery.sizeOf(context).width;
                      final double responsiveSize = screenWidth * 0.45;
                      final double size = responsiveSize.clamp(160.0, 320.0);
                      
                      return SizedBox(
                        width: size,
                        height: size,
                        child: Image.asset(
                          'assets/images/image.png',
                          fit: BoxFit.contain, // Ensures the entire logo is displayed without cropping corners
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.eco,
                            size: size * 0.5,
                            color: Colors.white, // Using white to contrast with the dark theme
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Brand name with premium fade
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      Text(
                        'AQUASOL',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 2,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PRECISION FARMING • AI DRIVEN',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(180),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Bottom loading indicator
            Positioned(
              bottom: 64,
              child: FadeIn(
                delay: const Duration(milliseconds: 2000),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

