import 'dart:math' as math;

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
      find.text('Case study · System Security and Threats'),
      findsOneWidget,
    );

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

  testWidgets('quick question gives immediate feedback and advances via arrow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.byTooltip('Next question'), findsNothing);

    final startsWithServer = find.text('No — always patch').evaluate().isNotEmpty;
    final firstCorrect = startsWithServer
        ? 'No — always patch'
        : 'B. No, at least require an additional PIN or biometric scan!';
    final secondIncorrect = startsWithServer
        ? 'A. Yes, another day, another dollar!'
        : 'Yes — if it still works';

    await tester.ensureVisible(find.text(firstCorrect));
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstCorrect));
    await tester.pumpAndSettle();

    expect(find.textContaining('That’s right'), findsOneWidget);
    expect(find.byTooltip('Next question'), findsOneWidget);

    await tester.tap(find.byTooltip('Next question'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2 of 2'), findsOneWidget);
    expect(find.text(firstCorrect), findsNothing);
    expect(find.byTooltip('Next question'), findsNothing);

    final secondCorrect = startsWithServer
        ? 'B. No, at least require an additional PIN or biometric scan!'
        : 'No — always patch';

    await tester.ensureVisible(find.text(secondIncorrect));
    await tester.pumpAndSettle();
    await tester.tap(find.text(secondIncorrect));
    await tester.pumpAndSettle();

    expect(find.textContaining('Not quite'), findsOneWidget);
    expect(find.byTooltip('Next question'), findsOneWidget);

    await tester.tap(find.text(secondCorrect));
    await tester.pumpAndSettle();

    expect(find.textContaining('That’s right'), findsOneWidget);
    expect(find.byTooltip('Next question'), findsOneWidget);

    await tester.tap(find.byTooltip('Next question'));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text(firstCorrect), findsOneWidget);
  });

  testWidgets('quick questions shuffle order across app launches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var sawServerFirst = false;
    var sawPortalFirst = false;

    for (var seed = 0; seed < 12; seed++) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(MyApp(questionRandom: math.Random(seed)));
      await tester.pumpAndSettle();

      if (find.text('No — always patch').evaluate().isNotEmpty) {
        sawServerFirst = true;
      }
      if (find
          .text('B. No, at least require an additional PIN or biometric scan!')
          .evaluate()
          .isNotEmpty) {
        sawPortalFirst = true;
      }
      if (sawServerFirst && sawPortalFirst) break;
    }

    expect(sawServerFirst, isTrue);
    expect(sawPortalFirst, isTrue);
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

  testWidgets('the assistant button opens a chat sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ask the study assistant'), findsOneWidget);

    await tester.tap(find.byTooltip('Ask the study assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Study assistant'), findsOneWidget);
    expect(find.text('Ask about the Change Healthcare attack'), findsOneWidget);
    expect(find.textContaining('I’m your study assistant'), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);

    await tester.tap(find.byTooltip('Close assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Study assistant'), findsNothing);

    // Re-open, then tap the dimmed area outside the sheet.
    await tester.tap(find.byTooltip('Ask the study assistant'));
    await tester.pumpAndSettle();
    expect(find.text('Study assistant'), findsOneWidget);

    await tester.tapAt(const Offset(195, 80));
    await tester.pumpAndSettle();
    expect(find.text('Study assistant'), findsNothing);
  });

  testWidgets('chat history survives closing the assistant', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = ChatSession(
      responder: (history) async => 'Canned study answer',
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(MyApp(chatSession: session));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ask the study assistant'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Explain MFA');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Explain MFA'), findsOneWidget);
    expect(find.text('Canned study answer'), findsOneWidget);

    await tester.tap(find.byTooltip('Close assistant'));
    await tester.pumpAndSettle();
    expect(find.text('Study assistant'), findsNothing);

    await tester.tap(find.byTooltip('Ask the study assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Explain MFA'), findsOneWidget);
    expect(find.text('Canned study answer'), findsOneWidget);

    // A fresh app start, like a page refresh, starts a new session.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ask the study assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Explain MFA'), findsNothing);
    expect(find.text('Canned study answer'), findsNothing);
  });
}
