import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquasol_app/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app with ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: AquaSolApp(),
      ),
    );
    
    // Allow initial animations and timers in SplashScreen to start
    await tester.pump();
    
    // SplashScreen has a 3.5s delay. Give it enough time to complete its task.
    // This avoids 'timer was not disposed' or 'widget tree was disposed' errors.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
