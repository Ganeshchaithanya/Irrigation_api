import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  bool _otpSent    = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _onGetOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).requestOtp(phone);
      setState(() => _otpSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent! Check terminal logs.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _onVerify() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 6-digit code')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).verifyOtp(_phoneCtrl.text.trim(), code);
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 90),

                // Shield icon
                FadeInDown(
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shieldCheck,
                        size: 42,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                FadeInDown(
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    _otpSent ? 'Enter OTP' : 'Welcome to AquaSol',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),

                const SizedBox(height: 10),

                FadeInDown(
                  delay: const Duration(milliseconds: 250),
                  child: Text(
                    _otpSent
                        ? 'Code sent to ${_phoneCtrl.text.trim()}'
                        : 'Smart irrigation management at your fingertips.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 40),

                // Phone or OTP input
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _otpSent
                      ? TextField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '• • • • • •',
                            hintStyle: TextStyle(
                                color: AppColors.textSecondary.withAlpha(80),
                                letterSpacing: 8,
                                fontSize: 28),
                            prefixIcon: const Icon(LucideIcons.keyRound,
                                color: AppColors.emerald),
                          ),
                        )
                      : TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '+91 98765 43210',
                            prefixIcon: Icon(LucideIcons.phone,
                                color: AppColors.emerald),
                            labelText: 'Phone Number',
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: authState.isLoading 
                      ? null 
                      : (_otpSent ? _onVerify : _onGetOtp),
                    child: authState.isLoading
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : Text(_otpSent ? 'Verify & Continue →' : 'Get OTP'),
                  ),
                ),

                if (!_otpSent) ...[
                  const SizedBox(height: 28),
                  FadeIn(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/onboarding'),
                      icon: const Icon(LucideIcons.logIn),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ],

                const Spacer(),

                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Text(
                      'Precision Farming, Powered by AI.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.emerald.withAlpha(160),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
