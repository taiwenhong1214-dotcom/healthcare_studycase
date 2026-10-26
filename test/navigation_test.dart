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
    expect(
      find.text('Welcome · System Security and Threats'),
      findsOneWidget,
    );

    for (final title in [
      'Missing MFA',
      'Outdated Systems',
      'Poor Network Separation',
    ]) {
      await tester.tap(find.widgetWithText(TextButton, title).first);
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

    await tester.tap(find.widgetWithText(TextButton, 'Outdated Systems').first);
    await tester.pumpAndSettle();

    expect(find.text('Back to home'), findsOneWidget);
    expect(find.textContaining('Old, unsupported software'), findsOneWidget);
  });
}
