import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquasol_app/core/router/app_router.dart';
import 'package:aquasol_app/core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AquaSolApp(),
    ),
  );
}

class AquaSolApp extends StatelessWidget {
  const AquaSolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AquaSol – Smart Irrigation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
