import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovator/Notification/FCM_Class.dart';
import 'package:innovator/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // OPTION 1: If InnovatorHomePage requires a String title
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InnovatorHomePage(),
        ),
      ),
    );

    // OPTION 2: If InnovatorHomePage requires named parameters
    // await tester.pumpWidget(
    //   ProviderScope(
    //     child: MaterialApp(
    //       home: InnovatorHomePage(
    //         title: 'Test App',
    //         // Add other required named parameters
    //       ),
    //     ),
    //   ),
    // );

    // OPTION 3: If InnovatorHomePage requires an index or number
    // await tester.pumpWidget(
    //   ProviderScope(
    //     child: MaterialApp(
    //       home: InnovatorHomePage(0), // or whatever number it expects
    //     ),
    //   ),
    // );

    // OPTION 4: Test the entire app instead
    // await tester.pumpWidget(
    //   ProviderScope(
    //     child: MyApp(),
    //   ),
    // );

    // Wait for the widget to be built
    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  // Test with mock data if your widget requires complex parameters
  testWidgets('Counter test with mock data', (WidgetTester tester) async {
    // Create mock data if needed
    final mockUserData = {
      'id': '123',
      'name': 'Test User',
      'email': 'test@example.com',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Add any provider overrides for testing
          // userProvider.overrideWith((ref) => mockUserData),
        ],
        child: MaterialApp(
          home: InnovatorHomePage(
            // Pass your mock data or required parameters

            // userData: mockUserData,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Your test assertions
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  // Simple integration test
  testWidgets('Integration test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: InnovatorHomePage(), // Test the entire app
      ),
    );

    await tester.pumpAndSettle();

    // Find and interact with widgets
    // This is more realistic for integration testing
    
    // Example: Test navigation
    // await tester.tap(find.byKey(Key('home_button')));
    // await tester.pumpAndSettle();
    // expect(find.text('Home Screen'), findsOneWidget);
  });
}