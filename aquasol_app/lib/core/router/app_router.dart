import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aquasol_app/features/splash/presentation/splash_screen.dart';
import 'package:aquasol_app/features/setup/presentation/setup_screen.dart';
import 'package:aquasol_app/features/auth/presentation/auth_screen.dart';
import 'package:aquasol_app/features/auth/presentation/signup_screen.dart';
import 'package:aquasol_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:aquasol_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aquasol_app/features/farm/presentation/farm_screen.dart';
import 'package:aquasol_app/features/zone/presentation/zone_detail_screen.dart';
import 'package:aquasol_app/features/zone/presentation/plant_stage_screen.dart';
import 'package:aquasol_app/features/irrigation/presentation/irrigation_screen.dart';
import 'package:aquasol_app/features/analytics/presentation/analytics_screen.dart';
import 'package:aquasol_app/features/alerts/presentation/alerts_screen.dart';
import 'package:aquasol_app/features/ai_chat/presentation/ai_chat_screen.dart';
import 'package:aquasol_app/features/crop_planner/presentation/crop_guide_screen.dart';
import 'package:aquasol_app/features/ai_decision/presentation/ai_decision_screen.dart';
import 'package:aquasol_app/features/diary/presentation/diary_screen.dart';
import 'package:aquasol_app/features/settings/presentation/settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/farm',
      builder: (context, state) => const FarmScreen(),
    ),
    GoRoute(
      path: '/zone/:id',
      builder: (context, state) =>
          ZoneDetailScreen(zoneId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/zone/:id/stage',
      builder: (context, state) =>
          PlantStageScreen(zoneId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/irrigation',
      builder: (context, state) => const IrrigationScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) => const CropGuideScreen(),
    ),
    GoRoute(
      path: '/crop-planner',
      builder: (context, state) => const CropGuideScreen(),
    ),
    GoRoute(
      path: '/decisions',
      builder: (context, state) => const AiDecisionScreen(),
    ),
    GoRoute(
      path: '/diary', 
      builder: (context, state) => const DiaryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
