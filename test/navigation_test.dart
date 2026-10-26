import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_studycase/main.dart';

void main() {
  testWidgets('home and lesson navigation work on mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Quick question'), findsOneWidget);
    expect(find.text('Welcome · System Security and Threats'), findsOneWidget);

    for (final (navLabel, title) in [
      ('MFA', 'Missing MFA'),
      ('Updates', 'Outdated Systems'),
      ('Network', 'Poor Network Separation'),
    ]) {
      await tester.tap(find.widgetWithText(TextButton, navLabel).first);
      await tester.pumpAndSettle();
      expect(find.text('Back to home'), findsOneWidget);
      expect(find.textContaining(title), findsWidgets);
    }

    await tester.tap(find.widgetWithText(TextButton, 'Home').first);
    await tester.pumpAndSettle();
    expect(find.text('Quick question'), findsOneWidget);
  });

  testWidgets('desktop navigation opens a lesson', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Updates').first);
    await tester.pumpAndSettle();

    expect(find.text('Back to home'), findsOneWidget);
    expect(find.textContaining('Old, unsupported software'), findsOneWidget);
  });

  testWidgets('the assistant bubble opens a chat sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ask the study assistant'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Study assistant'), findsOneWidget);
    expect(find.text('Ask about the Change Healthcare attack'), findsOneWidget);
    expect(find.textContaining('I’m your study assistant'), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);

    await tester.tap(find.byTooltip('Close assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Study assistant'), findsNothing);

    // Re-open, then tap the dimmed area outside the sheet.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Study assistant'), findsOneWidget);

    await tester.tapAt(const Offset(195, 80));
    await tester.pumpAndSettle();
    expect(find.text('Study assistant'), findsNothing);
  });
}
