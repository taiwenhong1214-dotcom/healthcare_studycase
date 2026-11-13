import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Palette
//
// A restrained, editorial dark theme. One accent colour carries interaction;
// red and amber appear only where the content itself is about risk.
// ---------------------------------------------------------------------------

const bgColor = Color(0xFF0A1118);
const surfaceColor = Color(0xFF111E29);
const raisedColor = Color(0xFF182936);
const lineColor = Color(0xFF263946);
const lineStrongColor = Color(0xFF323B48);

const textPrimary = Color(0xFFF1F4F6);
const textSecondary = Color(0xFFA9B3BF);
const textDim = Color(0xFF94A5B5);

const accentColor = Color(0xFF6FD3B5);
const accentInk = Color(0xFF0B211B);
const accentSurface = Color(0xFF132721);
const accentLine = Color(0xFF2A5045);

const dangerColor = Color(0xFFE58C8C);

const warningColor = Color(0xFFD8B36C);
const warningSurface = Color(0xFF2A2317);
const warningLine = Color(0xFF4B3E28);

const _bodyStyle = TextStyle(fontSize: 15.5, height: 1.7, color: textSecondary);
const _smallStyle = TextStyle(fontSize: 12.5, height: 1.5, color: textDim);

// ---------------------------------------------------------------------------
// Case study content
// ---------------------------------------------------------------------------

class Lesson {
  const Lesson({
    required this.number,
    required this.title,
    required this.navLabel,
    required this.icon,
    required this.kicker,
    required this.blurb,
    required this.summary,
    required this.weakness,
    required this.risk,
    required this.solution,
  });

  final String number;
  final String title;
  final String navLabel;
  final IconData icon;
  final String kicker;
  final String blurb;
  final String summary;
  final String weakness;
  final String risk;
  final String solution;
}

const lessons = [
  Lesson(
    number: '01',
    title: 'Missing MFA',
    navLabel: 'MFA',
    icon: Icons.smartphone_rounded,
    kicker: 'Stolen passwords',
    blurb: 'A password alone opened the door.',
    summary:
        'With stolen staff credentials, the attackers walked straight into '
        'the portal. Nothing checked that they were really the staff member.',
    weakness:
        'The portal had no MFA, so anyone with a password could get in, '
        'employee or not.',
    risk:
        'Attackers could reach sensitive medical data, such as protected '
        'health information (PHI) and personally identifiable information '
        '(PII), and leak it.',
    solution:
        'Require MFA at every entry point, using at least two different '
        'methods such as a fingerprint, security PIN, or face scan. FIDO2 '
        'also supports passwordless sign-in.',
  ),
  Lesson(
    number: '02',
    title: 'Outdated Systems',
    navLabel: 'Updates',
    icon: Icons.dns_rounded,
    kicker: 'Known exploits',
    blurb: 'Old servers kept known flaws alive.',
    summary:
        'Once inside, the attackers found systems that had missed updates. '
        'Known flaws in that old software gave them a firmer foothold.',
    weakness: 'Old, unsupported software may stop receiving security updates.',
    risk:
        'Attackers could exploit published vulnerabilities that already had '
        'fixes available.',
    solution:
        'Test and install updates on a regular schedule, and replace systems '
        'that can no longer receive patches.',
  ),
  Lesson(
    number: '03',
    title: 'Poor Network Separation',
    navLabel: 'Network',
    icon: Icons.hub_rounded,
    kicker: '',
    blurb: '',
    summary: '',
    weakness: '',
    risk: '',
    solution: '',
  ),
];

class _QuickQuestion {
  const _QuickQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.correctFeedback,
    required this.incorrectFeedback,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String correctFeedback;
  final String incorrectFeedback;
}

const _quickQuestions = [
  _QuickQuestion(
    prompt:
        'A hospital’s old server still works. Should it skip security updates?',
    choices: ['No — always patch', 'Yes — if it still works'],
    correctIndex: 0,
    correctFeedback:
        'That’s right. Working is not the same as secure. Patch it, test with '
        'sample claims, and keep a rollback plan.',
    incorrectFeedback:
        'Not quite. Legacy systems are a favourite target. Updates still '
        'matter even when the hardware keeps running.',
  ),
  _QuickQuestion(
    prompt:
        'A hospital’s portal requires username and password before login. '
        'That should be enough right?',
    choices: [
      'A. Yes, another day, another dollar!',
      'B. No, at least require an additional PIN or biometric scan!',
    ],
    correctIndex: 1,
    correctFeedback:
        'That’s right. Stolen passwords alone let attackers straight into '
        'the portal. Require MFA at every entry point using another factor '
        'like a PIN or biometric scan.',
    incorrectFeedback:
        'Not quite. Passwords can be stolen or leaked. Without a second '
        'factor like a PIN or biometric scan, anyone with those credentials '
        'can log in.',
  ),
];

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.chatSession, this.questionRandom});

  /// Kept alive across assistant open/close cycles for tests and previews.
  /// A normal app start creates a fresh session.
  final ChatSession? chatSession;

  /// Optional random generator to keep question order deterministic in tests.
  final math.Random? questionRandom;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Change Healthcare • Security Lessons',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Arimo',
        scaffoldBackgroundColor: bgColor,
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          onPrimary: accentInk,
          surface: surfaceColor,
          onSurface: textPrimary,
        ),
        splashFactory: NoSplash.splashFactory,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            textStyle: const TextStyle(
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: AppShell(
        chatSession: chatSession,
        questionRandom: questionRandom,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.chatSession, this.questionRandom});

  final ChatSession? chatSession;
  final math.Random? questionRandom;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 0 is the overview. 1, 2 and 3 are the three lessons.
  int _selectedPage = 0;
  final ScrollController _scrollController = ScrollController();
  late final ChatSession _chatSession;
  late final bool _ownsChatSession;
  late final List<_QuickQuestion> _questions;
  int _questionIndex = 0;
  int _selectedChoice = -1;

  @override
  void initState() {
    super.initState();
    _ownsChatSession = widget.chatSession == null;
    _chatSession = widget.chatSession ?? ChatSession();
    _questions = List<_QuickQuestion>.of(_quickQuestions)
      ..shuffle(widget.questionRandom ?? math.Random());

    // Allow shareable links such as /?lesson=2. This also makes it easy to
    // preview a specific lesson while working on the design.
    final requested = int.tryParse(Uri.base.queryParameters['lesson'] ?? '');
    if (requested != null && requested >= 1 && requested <= lessons.length) {
      _selectedPage = requested;
    }
  }

  @override
  void dispose() {
    if (_ownsChatSession) _chatSession.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page == _selectedPage) {
      _scrollToTop();
      return;
    }
    setState(() => _selectedPage = page);
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth <= 720;
    // Wide screens get a top bar like a normal website. Phones and narrow
    // tablets keep the bottom bar, which is easier to reach with a thumb.
    final useTopBar = screenWidth >= 960;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: useTopBar
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: _buildTopBar(),
            )
          : null,
      body: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 16,
          height: 1.6,
          letterSpacing: 0,
          color: textPrimary,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _selectedPage == 0 ? 1080 : 800,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 22 : 40,
                    isMobile ? 28 : 48,
                    isMobile ? 22 : 40,
                    isMobile ? 56 : 80,
                  ),
                  // SingleChildScrollView does not add a repaint boundary
                  // (ListView does). Without one, every scroll frame redraws
                  // the whole page instead of just moving it.
                  child: RepaintBoundary(
                    child: _selectedPage == 0
                        ? _buildHome(isMobile)
                        : _buildLessonPage(isMobile),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: useTopBar ? null : _buildBottomNav(isMobile),
    );
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: lineColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  // The brand gives up space first, so the links never
                  // overflow on a narrower window.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildBrand(),
                    ),
                  ),
                  _topLink(page: 0, label: 'Home'),
                  for (var i = 0; i < lessons.length; i++)
                    _topLink(
                      page: i + 1,
                      label: lessons[i].navLabel,
                      number: lessons[i].number,
                      tooltip: lessons[i].title,
                    ),
                  const SizedBox(width: 20),
                  Tooltip(
                    message: 'Ask the study assistant',
                    child: OutlinedButton.icon(
                      onPressed: _openAssistant,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 17,
                      ),
                      label: const Text('Ask assistant'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: const BorderSide(color: accentLine),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return InkWell(
      onTap: () => _goTo(0),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentSurface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: accentLine),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change Healthcare',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Security case study',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topLink({
    required int page,
    required String label,
    String? number,
    String? tooltip,
  }) {
    final selected = _selectedPage == page;
    final link = Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: TextButton(
        onPressed: () => _goTo(page),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: selected ? textPrimary : textSecondary,
          overlayColor: Colors.transparent,
          textStyle: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (number != null) ...[
              Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? accentColor : textDim,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: tooltip == null ? link : Tooltip(message: tooltip, child: link),
    );
  }

  Widget _buildBottomNav(bool isMobile) {
    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: lineColor)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _navButton(
                      page: 0,
                      label: 'Home',
                      tooltip: 'Overview',
                      icon: Icons.home_outlined,
                    ),
                  ),
                  for (var i = 0; i < lessons.length; i++)
                    Expanded(
                      child: _navButton(
                        page: i + 1,
                        label: lessons[i].navLabel,
                        tooltip: lessons[i].title,
                        icon: lessons[i].icon,
                      ),
                    ),
                  Expanded(
                    child: _navButton(
                      label: 'Ask',
                      tooltip: 'Ask the study assistant',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: _openAssistant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A bottom bar item. Pass [page] to switch pages, or [onPressed] for an
  /// action such as opening the assistant.
  Widget _navButton({
    int? page,
    required String label,
    required String tooltip,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    final selected = page != null && _selectedPage == page;
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed: onPressed ?? () => _goTo(page!),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: const Size(0, 52),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: selected ? accentColor : textDim,
            overlayColor: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only the icon gets the highlight pill, so the selected tab
              // stands out without the whole cell turning into a block.
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 52,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? accentSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? accentLine : Colors.transparent,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: selected ? accentColor : textDim,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accentColor : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAssistant() {
    final isMobile = MediaQuery.sizeOf(context).width <= 720;
    if (isMobile) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color.fromRGBO(0, 0, 0, 0.72),
        builder: (context) => StudyAssistantSheet(session: _chatSession),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.72),
      builder: (context) =>
          StudyAssistantSheet(session: _chatSession, isDialog: true),
    );
  }

  void _selectChoice(int choice) {
    setState(() => _selectedChoice = choice);
  }

  void _nextQuestion() {
    setState(() {
      _questionIndex = (_questionIndex + 1) % _questions.length;
      _selectedChoice = -1;
    });
  }

  // -------------------------------------------------------------------------
  // Overview
  // -------------------------------------------------------------------------

  Widget _buildHome(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(isMobile),
        SizedBox(height: isMobile ? 20 : 24),
        _buildStats(isMobile),
        SizedBox(height: isMobile ? 40 : 48),
        _QuestionSection(
          question: _questions[_questionIndex],
          questionNumber: _questionIndex + 1,
          totalQuestions: _questions.length,
          selected: _selectedChoice,
          onSelect: _selectChoice,
          onNext: _nextQuestion,
        ),
        SizedBox(height: isMobile ? 40 : 48),
        const _FooterSection(),
      ],
    );
  }

  Widget _buildHero(bool isMobile) {
    final stacked = MediaQuery.sizeOf(context).width < 900;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: dangerColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Case study · System Security and Threats',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 14 : 18),
        Text(
          'The Change Healthcare ransomware attack',
          style: TextStyle(
            fontSize: isMobile ? 32 : 44,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Stolen login details led to a nationwide healthcare outage in '
            '2024. This short case study looks at the three weaknesses that '
            'made it possible — and what would have stopped them.',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16.5,
              height: 1.7,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );

    final gif = Semantics(
      image: true,
      label: 'Laptop hacking animation',
      child: Container(
        width: stacked ? 120 : 200,
        height: stacked ? 120 : 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lineColor),
          color: surfaceColor,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        // The GIF changes every frame. Its own repaint boundary stops each
        // frame from redrawing the rest of the page, which made scrolling lag.
        child: RepaintBoundary(
          child: Image.asset('laptop-hacking.gif', fit: BoxFit.contain),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17343A), surfaceColor, Color(0xFF142336)],
        ),
        border: Border.all(color: lineStrongColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Picture first, then the text, so the card reads top to
              // bottom without the GIF interrupting the paragraph and button.
              children: [gif, const SizedBox(height: 20), copy],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 40),
                gif,
              ],
            ),
          const SizedBox(height: 28),
          const Divider(height: 1, color: lineColor),
          const SizedBox(height: 22),
          _buildHeroActions(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeroActions(bool isMobile) {
    const meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 16, color: accentColor),
        SizedBox(width: 8),
        Flexible(
          child: Text('3 lessons · About 8 minutes', style: _smallStyle),
        ),
      ],
    );
    final button = SizedBox(
      width: isMobile ? double.infinity : 196,
      height: 52,
      child: FilledButton(
        onPressed: () => _goTo(1),
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: accentInk,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: const TextStyle(
            fontFamily: 'Arimo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Start learning'),
              ),
            ),
            SizedBox(width: 16),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [meta, const SizedBox(height: 16), button],
          )
        : Row(
            children: [
              const Expanded(child: meta),
              const SizedBox(width: 20),
              button,
            ],
          );
  }

  Widget _buildStats(bool isMobile) {
    const items = [
      ('192.7M', 'People affected'),
      (r'$22M', 'Ransom paid'),
      ('Feb 2024', 'Attack began'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineColor),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      items[i].$1,
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 30,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 12.5,
                      height: 1.4,
                      color: textDim,
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Container(width: 1, height: isMobile ? 30 : 38, color: lineColor),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Lesson
  // -------------------------------------------------------------------------

  Widget _buildLessonPage(bool isMobile) {
    final lesson = lessons[_selectedPage - 1];
    final isLastLesson = _selectedPage == lessons.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: () => _goTo(0),
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: const Text('Back to home'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: textSecondary,
                overlayColor: Colors.transparent,
                textStyle: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Lesson $_selectedPage of ${lessons.length}',
              style: _smallStyle,
            ),
          ],
        ),
        SizedBox(height: isMobile ? 28 : 36),
        if (lesson.kicker.isNotEmpty) ...[
          Text(
            lesson.kicker.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          lesson.title,
          style: TextStyle(
            fontSize: isMobile ? 32 : 42,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        if (lesson.summary.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              lesson.summary,
              style: TextStyle(
                fontSize: isMobile ? 15 : 16.5,
                height: 1.7,
                color: textSecondary,
              ),
            ),
          ),
        SizedBox(height: isMobile ? 32 : 40),
        if (lesson.weakness.isEmpty)
          _buildComingSoon()
        else ...[
          _buildDetail('Weakness', lesson.weakness, warningColor, isMobile),
          const Divider(height: 1, thickness: 1, color: lineColor),
          _buildDetail('Risk', lesson.risk, dangerColor, isMobile),
          const Divider(height: 1, thickness: 1, color: lineColor),
          _buildFix(lesson.solution, isMobile),
        ],
        SizedBox(height: isMobile ? 36 : 44),
        if (isLastLesson && lesson.summary.isNotEmpty) _buildCompletion(),
        if (!isLastLesson) _buildNextLesson(lessons[_selectedPage], isMobile),
        const SizedBox(height: 32),
        const _FooterSection(),
      ],
    );
  }

  Widget _buildDetail(String label, String body, Color tone, bool isMobile) {
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: tone,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.7,
                color: textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: labelWidget,
            ),
          ),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown while a teammate is still writing this lesson, so the page does
  /// not show empty Weakness / Risk / Fix headings.
  Widget _buildComingSoon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 20, color: textDim),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This lesson is still being written. Check back soon.',
              style: _bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFix(String solution, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 4),
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: accentSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, size: 17, color: accentColor),
              SizedBox(width: 8),
              Text(
                'The fix',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            solution,
            style: TextStyle(
              fontSize: isMobile ? 15.5 : 16,
              height: 1.7,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLesson(Lesson next, bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _goTo(_selectedPage + 1),
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0x08FFFFFF),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: lineColor),
              bottom: BorderSide(color: lineColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('NEXT LESSON', style: _smallStyle),
                    const SizedBox(height: 4),
                    Text(
                      next.title,
                      style: TextStyle(
                        fontSize: isMobile ? 17 : 19,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletion() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: lineColor),
          bottom: BorderSide(color: lineColor),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You’ve reviewed all three weaknesses.',
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'The quick question on the overview is a good way to check what '
            'stuck.',
            style: _bodyStyle,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick question
// ---------------------------------------------------------------------------

class _QuestionSection extends StatelessWidget {
  const _QuestionSection({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  final _QuickQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width <= 720;
    final showFeedback = selected != -1;
    final isCorrect = selected == question.correctIndex;

    return Container(
      padding: EdgeInsets.all(isMobile ? 22 : 28),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                const Text(
                  'Quick question',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: accentColor,
                  ),
                ),
                Text(
                  'Question $questionNumber of $totalQuestions',
                  style: _smallStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.prompt,
            style: TextStyle(
              fontSize: isMobile ? 20 : 23,
              height: 1.4,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              children: [
                for (var i = 0; i < question.choices.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _buildChoice(question.choices[i], i),
                ],
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < question.choices.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: _buildChoice(question.choices[i], i)),
                  ],
                ],
              ),
            ),
          if (showFeedback) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect ? accentSurface : warningSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect ? accentLine : warningLine,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 18,
                          color: isCorrect ? accentColor : warningColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? question.correctFeedback
                                : question.incorrectFeedback,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: onNext,
                    tooltip: 'Next question',
                    style: IconButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: accentInk,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoice(String label, int value) {
    final isSelected = selected == value;
    final isCorrect = value == question.correctIndex;
    final selectedColor = isCorrect ? accentColor : warningColor;

    return Material(
      color: isSelected
          ? (isCorrect ? accentSurface : warningSurface)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : lineStrongColor,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? selectedColor : textDim,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? textPrimary : textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: lineColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Learn more: ', style: _smallStyle),
              _link(
                'CISA security guide',
                'https://www.cisa.gov/stopransomware/ransomware-guide',
              ),
              const Text('  ·  ', style: _smallStyle),
              _link(
                'NIST patching guide',
                'https://csrc.nist.gov/pubs/sp/1800/31/final',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'System Fundamentals · Extra learning content',
            style: _smallStyle,
          ),
        ],
      ),
    );
  }

  Widget _link(String label, String url) {
    return TextButton(
      onPressed: () => _openLink(url),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: accentColor,
        overlayColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        textStyle: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 12.5,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.5,
          color: accentColor,
          decoration: TextDecoration.underline,
          decorationColor: accentLine,
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      debugPrint('Could not open $url');
    }
  }
}

// ---------------------------------------------------------------------------
// Assistant session
// ---------------------------------------------------------------------------

class RateLimitException implements Exception {
  const RateLimitException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isIntro = false,
  });

  final String text;
  final bool isUser;
  final bool isIntro;
}

typedef ChatResponder =
    Future<String> Function(List<Map<String, String>> history);

/// Holds the conversation for as long as the app is running. Closing the
/// assistant panel does not destroy it; a page refresh creates a new session.
class ChatSession extends ChangeNotifier {
  ChatSession({ChatResponder? responder})
    : _responder = responder ?? _requestReply;

  final ChatResponder _responder;
  final List<ChatMessage> messages = [
    ChatMessage(
      text:
          'Hi! I’m your study assistant for the Change Healthcare case study. '
          'Ask about the attack or the three lessons.',
      isUser: false,
      isIntro: true,
    ),
  ];

  bool _sending = false;
  bool _disposed = false;

  bool get sending => _sending;

  Future<void> send(String rawText) async {
    if (_disposed) return;
    final text = rawText.trim();
    if (text.isEmpty || _sending) return;

    messages.add(ChatMessage(text: text, isUser: true));
    _sending = true;
    notifyListeners();

    try {
      final history = messages
          .where((message) => !message.isIntro)
          .map(
            (message) => {
              'role': message.isUser ? 'user' : 'assistant',
              'content': message.text,
            },
          )
          .toList();
      final reply = await _responder(history);
      if (_disposed) return;
      messages.add(ChatMessage(text: reply, isUser: false));
    } catch (error) {
      if (_disposed) return;
      debugPrint('Study assistant request failed: $error');
      final errorText = error is RateLimitException
          ? error.message
          : 'Sorry, I can’t reach the study assistant right now. '
                'Please check your connection and try again.';
      messages.add(ChatMessage(text: errorText, isUser: false));
    } finally {
      _sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static Future<String> _requestReply(List<Map<String, String>> history) async {
    final response = await http
        .post(
          _chatEndpoint(),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'messages': history}),
        )
        .timeout(const Duration(seconds: 70));

    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['error'] is String) {
            throw RateLimitException(data['error'] as String);
          }
        } catch (e) {
          if (e is RateLimitException) rethrow;
        }
        throw const RateLimitException(
          'Please slow down and wait a few seconds before asking again.',
        );
      }
      throw Exception('Assistant returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final reply = data is Map<String, dynamic> ? data['reply'] : null;
    if (reply is! String || reply.trim().isEmpty) {
      throw Exception('Assistant returned an empty reply');
    }
    return reply.trim();
  }

  static Uri _chatEndpoint() {
    const override = String.fromEnvironment('AI_CHAT_ENDPOINT');
    if (override.isNotEmpty) return Uri.parse(override);
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return Uri.parse('https://healthcare-studycase.space/api/chat');
      }
      return Uri.base.resolve('/api/chat');
    }
    return Uri.parse('https://healthcare-studycase.space/api/chat');
  }
}

// ---------------------------------------------------------------------------
// Assistant sheet
// ---------------------------------------------------------------------------

class StudyAssistantSheet extends StatefulWidget {
  const StudyAssistantSheet({
    super.key,
    required this.session,
    this.isDialog = false,
  });

  final ChatSession session;

  /// A dialog on desktop, a bottom sheet on phones.
  final bool isDialog;

  @override
  State<StudyAssistantSheet> createState() => _StudyAssistantSheetState();
}

class _StudyAssistantSheetState extends State<StudyAssistantSheet> {
  static const _suggestions = [
    'Summarize the attack in 150 words',
    'Why does MFA matter?',
    'How could this be prevented?',
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    // Reopening the panel should show the latest message, not the intro.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || widget.session.sending) return;

    _inputController.clear();
    await widget.session.send(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final panelHeight = math.min(700.0, availableHeight * 0.88);
    final panelWidth = widget.isDialog ? 460.0 : 560.0;
    final bottomSafeArea = media.viewInsets.bottom > 0
        ? 0.0
        : media.padding.bottom;

    final panel = Container(
      width: widget.isDialog ? panelWidth : double.infinity,
      height: panelHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: lineColor),
        borderRadius: widget.isDialog
            ? BorderRadius.circular(18)
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (!widget.isDialog) _buildDragHandle(),
          _buildHeader(context),
          const Divider(height: 1, thickness: 1, color: lineColor),
          Expanded(child: _buildMessages()),
          _buildComposer(bottomSafeArea),
        ],
      ),
    );

    if (widget.isDialog) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: panel,
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      // Without heightFactor, Align fills the whole sheet route and swallows
      // taps that should land on the modal barrier. Shrink-wrap to the panel.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: panelWidth),
        child: Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: panel,
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: lineStrongColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Study assistant',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask about the Change Healthcare attack',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: textDim),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Close assistant',
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: textDim,
              padding: EdgeInsets.zero,
              minimumSize: const Size(38, 38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    final messages = widget.session.messages;
    final sending = widget.session.sending;
    final showSuggestions = messages.length == 1 && !sending;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      children: [
        for (final message in messages) _MessageBubble(message: message),
        if (showSuggestions) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in _suggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: sending ? null : () => _sendMessage(suggestion),
                  backgroundColor: surfaceColor,
                  side: const BorderSide(color: lineColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  labelStyle: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    height: 1.3,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        if (sending) ...[const SizedBox(height: 14), const _ThinkingBubble()],
      ],
    );
  }

  Widget _buildComposer(double bottomSafeArea) {
    final sending = widget.session.sending;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafeArea),
      decoration: const BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: lineColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(
                fontFamily: 'Arimo',
                fontSize: 14,
                height: 1.45,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Ask about the case study…',
                hintStyle: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 14,
                  color: textDim,
                ),
                filled: true,
                fillColor: surfaceColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: lineColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: lineColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentColor, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: sending ? null : () => _sendMessage(),
              tooltip: 'Send',
              style: IconButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: accentInk,
                disabledBackgroundColor: raisedColor,
                disabledForegroundColor: textDim,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentInk,
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final baseStyle = TextStyle(
      fontFamily: 'Arimo',
      fontSize: 13.5,
      height: 1.6,
      color: textPrimary,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? accentSurface : surfaceColor,
          border: Border.all(color: isUser ? accentLine : lineColor),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: _buildFormattedContent(message.text, baseStyle, isUser),
      ),
    );
  }

  Widget _buildFormattedContent(
    String rawText,
    TextStyle baseStyle,
    bool isUser,
  ) {
    if (isUser) {
      return Text(rawText.trim(), style: baseStyle);
    }

    // Strip any asterisks and normalise bullets and whitespace.
    final text = rawText
        .replaceAll(RegExp(r'^\s*[-*•]\s*', multiLine: true), '• ')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'^(•\s*)+', multiLine: true), '• ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    final titleRegex = RegExp(r'^(•\s*|\d+\.\s*)([^:：\n]+[:：])(.*)$');

    if (!text.contains('\n') && !titleRegex.hasMatch(text)) {
      return Text(text, style: baseStyle);
    }

    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = titleRegex.firstMatch(line);
      if (match != null) {
        spans.add(TextSpan(text: match.group(1), style: baseStyle));
        spans.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        );
        spans.add(TextSpan(text: match.group(3), style: baseStyle));
      } else {
        spans.add(TextSpan(text: line, style: baseStyle));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return Text.rich(TextSpan(children: spans), style: baseStyle);
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
        ),
        SizedBox(width: 10),
        Text(
          'Thinking…',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 13,
            height: 1.4,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
