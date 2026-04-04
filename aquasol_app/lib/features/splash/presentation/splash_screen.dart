import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aquasol_app/providers/auth_provider.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // We use sequential fade/scale/swap logic
  bool _showText = false;
  bool _showSprout = false;
  bool _showFinalLogo = false;

  @override
  void initState() {
    super.initState();
    _playCinematicSequence();
  }

  void _playCinematicSequence() async {
    // 1. Water Drop falls (Wait 1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 2. Ripple & Sprout blooms
    if (mounted) setState(() => _showSprout = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 3. Sprout transitions into the final Logo and Text Appears
    if (mounted) setState(() {
      _showFinalLogo = true;
      _showText = true;
    });

    // 4. Wait for user to read taglines, then route
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.userId == null) {
      context.go('/auth');
      return;
    }

    await ref.read(farmProvider.notifier).loadFarm(silent: true);
    if (!mounted) return;

    final farm = ref.read(farmProvider);
    if (farm.hasValue && farm.value != null && farm.value!.acres.isNotEmpty) {
      context.go('/dashboard');
    } else {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3D2F), // Muted dark emerald to match video
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF235544), // Slightly lighter center
              Color(0xFF10271E), // Deep dark vignette edge
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sequence 1 & 2: The Water Drop into Sprout
            if (!_showFinalLogo) ...[
               if (!_showSprout)
                 // Initial Water Drop
                 SlideInDown(
                   duration: const Duration(seconds: 1),
                   child: FadeIn(
                     duration: const Duration(seconds: 1),
                     child: _buildAsset('assets/images/splash_water_drop.png'),
                   ),
                 )
               else
                 // Sprout emerging
                 ZoomIn(
                   duration: const Duration(milliseconds: 800),
                   child: _buildAsset('assets/images/splash_sprout.png'),
                 ),
            ],

            // Sequence 3: Final Logo
            if (_showFinalLogo)
               ZoomIn(
                 duration: const Duration(milliseconds: 800),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      // The AI generated or original logo
                      Image.asset(
                         'assets/images/image.png',
                         height: 160,
                         errorBuilder: (ctx, _, __) => const Icon(Icons.eco, size: 160, color: Colors.blueAccent),
                      ),
                   ],
                 ),
               ),

            // Taglines
            if (_showText)
               Positioned(
                 bottom: MediaQuery.of(context).size.height * 0.35,
                 child: Column(
                   children: [
                     FadeInUp(
                       duration: const Duration(milliseconds: 800),
                       child: const Text('AQUASOL', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 8)),
                     ),
                     const SizedBox(height: 8),
                     FadeIn(
                       delay: const Duration(milliseconds: 500),
                       duration: const Duration(milliseconds: 1000),
                       child: const Text('Intelligence in every drop', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic)),
                     ),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsset(String path) {
    return Image.asset(
      path,
      height: 250,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) => const SizedBox(
        height: 250,
        child: Icon(Icons.water_drop, size: 100, color: Colors.white30),
      ),
    );
  }
}
