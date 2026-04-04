import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/auth_provider.dart';
import 'package:aquasol_app/providers/farm_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _routeToNext() async {
    await ref.read(farmProvider.notifier).loadFarm(silent: true);
    if (!mounted) return;
    
    final farm = ref.read(farmProvider);
    if (farm.hasValue && farm.value != null && farm.value!.acres.isNotEmpty) {
      context.go('/dashboard');
    } else {
      context.go('/setup');
    }
  }

  Future<void> _onLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).login(email, pass);
      if (mounted) _routeToNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _onGoogleLogin() async {
    try {
      await ref.read(authProvider.notifier).googleLogin(
        "demo.google@aquasol.com", 
        "Google User", 
        "1234567890"
      );
      if (mounted) _routeToNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Failed: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Premium Gradient Background ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Organic Glass Blobs ─────────────────────────────────────
          Positioned(
            top: -100,
            right: -50,
            child: FadeIn(
              duration: const Duration(seconds: 4),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandEmerald.withAlpha(20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: FadeIn(
              duration: const Duration(seconds: 5),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.waterMid.withAlpha(20),
                ),
              ),
            ),
          ),

          // ── Main Content ───────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: const Icon(LucideIcons.droplet, size: 48, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: const Text(
                        'AquaSol Secure',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInDown(
                      delay: const Duration(milliseconds: 400),
                      child: const Text(
                        'AI-DRIVEN AGRICULTURE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 3),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ── Glassmorphic Card ──────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white.withAlpha(30)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField('EMAIL', 'email@aquasol.com', LucideIcons.mail, _emailCtrl, isEmail: true),
                                const SizedBox(height: 16),
                                _buildTextField('PASSWORD', '••••••••', LucideIcons.lock, _passwordCtrl, isPassword: true),
                                const SizedBox(height: 24),
                                _buildActionButton(authState.isLoading),
                                const SizedBox(height: 16),
                                _buildGoogleButton(authState.isLoading),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text(
                          'DON\'T HAVE AN ACCOUNT? SIGN UP',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 900),
                      child: const Text(
                        'POWERED BY AI • PRECISION AGRICULTURE',
                        style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isEmail = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.growthGradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.brandEmerald.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _onLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text('LOG IN →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _onGoogleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.chrome, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Text('CONTINUE WITH GOOGLE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}
