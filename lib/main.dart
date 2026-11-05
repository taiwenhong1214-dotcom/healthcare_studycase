import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Cyber Sentinel Dark Edition - Change Healthcare Security Case Study

// Obsidian Cyber Palette
const bgDark = Color(0xFF090D16); // Deep space obsidian
const surfaceDark = Color(0xFF0F172A); // Elevated cyber slate
const cardDark = Color(0xFF131D30); // Incident card slate
const cardBorder = Color(0xFF1E293B); // High-tech subtle border
const cardBorderGlow = Color(0xFF2C3E55);

// Neon Cyber Accents
const cyberGreen = Color(0xFF00E599); // Neon terminal emerald
const cyberGreenDim = Color(0xFF03261C);
const cyberGreenBorder = Color(0xFF054D38);

const textPrimary = Color(0xFFF8FAFC); // Clean crisp white-slate
const textSecondary = Color(0xFF94A3B8); // Muted slate
const textDim = Color(0xFF64748B);

// Threat Severity Colors
const threatRed = Color(0xFFFF4D4F); // Ransomware / Incident red
const threatRedBg = Color(0xFF220D12);
const threatRedBorder = Color(0xFF4C161E);

const threatAmber = Color(0xFFFBBF24); // Warning / Vulnerability
const threatAmberBg = Color(0xFF24190B);
const threatAmberBorder = Color(0xFF4A3412);

const cyberBlue = Color(0xFF38BDF8); // Protocol / Analysis blue
const cyberBlueBg = Color(0xFF0A2234);
const cyberBlueBorder = Color(0xFF13455E);

// Compatibility aliases
const bgColor = bgDark;
const primaryColor = cyberGreen;
const textColor = textPrimary;
const mutedTextColor = textSecondary;
const tagBgColor = cyberGreenDim;
const tagTextColor = cyberGreen;
const borderColor = cardBorder;
const subtleBorderColor = Color(0xFF192438);
const numberBgColor = Color(0xFF16233B);
const dividerColor = Color(0xFF1E293B);
const questionBgColor = Color(0xFF0D1B2A);
const footerTextColor = textDim;
const linkColor = cyberGreen;

// Semantic tags for Security Breakdown
const weaknessBgColor = threatAmberBg;
const weaknessBorderColor = threatAmberBorder;
const weaknessTextColor = threatAmber;

const riskBgColor = threatRedBg;
const riskBorderColor = threatRedBorder;
const riskTextColor = threatRed;

const solutionBgColor = cyberGreenDim;
const solutionBorderColor = cyberGreenBorder;
const solutionTextColor = cyberGreen;

class Lesson {
  const Lesson({
    required this.number,
    required this.title,
    required this.navLabel,
    required this.sectionLabel,
    required this.icon,
    required this.weakness,
    required this.risk,
    required this.solution,
    required this.stageName,
    required this.killChainPhase,
    required this.tacticDescription,
    required this.nextPhasePreview,
  });

  final String number;
  final String title;
  final String navLabel;
  final String sectionLabel;
  final IconData icon;
  final String weakness;
  final String risk;
  final String solution;
  final String stageName;
  final String killChainPhase;
  final String tacticDescription;
  final String nextPhasePreview;
}

const lessons = [
  Lesson(
    number: '01',
    title: 'Missing MFA',
    navLabel: 'MFA',
    sectionLabel: 'First vulnerability',
    icon: Icons.smartphone_rounded,
    weakness: 'The affected remote-access portal only required login details.',
    risk: 'A stolen password could let an attacker enter.',
    solution: 'Require MFA, such as a password plus a security key.',
    stageName: 'Stage 01',
    killChainPhase: 'Initial Infiltration',
    tacticDescription:
        'Attackers used compromised credentials against a single-factor Citrix portal.',
    nextPhasePreview:
        'Stage 02: Weaponization & Exploiting Unpatched Edge Gateways',
  ),
  Lesson(
    number: '02',
    title: 'Outdated Systems',
    navLabel: 'Updates',
    sectionLabel: 'Second vulnerability',
    icon: Icons.dns_rounded,
    weakness: 'Old, unsupported software may stop receiving security updates.',
    risk: 'Attackers could exploit known security flaws.',
    solution: 'Test and install updates. Replace unsupported systems.',
    stageName: 'Stage 02',
    killChainPhase: 'Weaponization & Foothold',
    tacticDescription:
        'Once inside, attackers leveraged known vulnerabilities in unpatched legacy servers.',
    nextPhasePreview:
        'Stage 03: Lateral Movement Across Flat Internal Network',
  ),
  Lesson(
    number: '03',
    title: 'Poor Network Separation',
    navLabel: 'Network',
    sectionLabel: 'Third vulnerability',
    icon: Icons.hub_rounded,
    weakness: 'Unnecessary connections can let attackers reach other systems.',
    risk: 'One infected device could lead to a wider outage.',
    solution: 'Separate important systems and allow only necessary access.',
    stageName: 'Stage 03',
    killChainPhase: 'Lateral Expansion & Impact',
    tacticDescription:
        'Due to flat network topology, ransomware spread unhindered into payment processors.',
    nextPhasePreview:
        'Forensics Complete: Proceed to Incident Defense Assessment',
  ),
];

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.chatSession});

  /// Kept alive across assistant open/close cycles for tests and previews.
  /// A normal app start creates a fresh session.
  final ChatSession? chatSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Change Healthcare • Security Lessons',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Arimo',
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: cyberGreen,
          surface: surfaceDark,
        ),
        splashFactory: NoSplash.splashFactory,
      ),
      home: AppShell(chatSession: chatSession),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.chatSession});

  final ChatSession? chatSession;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 0 is the welcome page. 1, 2 and 3 are the three lessons.
  int _selectedPage = 0;
  final ScrollController _scrollController = ScrollController();
  late final ChatSession _chatSession;
  late final bool _ownsChatSession;
  final Set<int> _mitigatedPages = <int>{};

  @override
  void initState() {
    super.initState();
    _ownsChatSession = widget.chatSession == null;
    _chatSession = widget.chatSession ?? ChatSession();
  }

  @override
  void dispose() {
    if (_ownsChatSession) _chatSession.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page > 0) {
      _mitigatedPages.add(page);
    }
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
    final titleSize = (screenWidth * 0.042).clamp(28.0, 40.0).toDouble();

    return Scaffold(
      backgroundColor: bgColor,
      body: DefaultTextStyle(
        // Material's default text style adds letter spacing, which makes
        // the text wrap differently from the original CSS. Keep it at zero.
        style: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 16,
          height: 1.6,
          letterSpacing: 0,
          color: textColor,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 18 : 24,
                    isMobile ? 18 : 28,
                    isMobile ? 18 : 24,
                    isMobile ? 30 : 40,
                  ),
                  child: _selectedPage == 0
                      ? _buildHome(isMobile, titleSize)
                      : _buildLessonPage(isMobile),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDockStatusPill(),
              const SizedBox(height: 6),
              _buildFloatingDock(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAssistantButton(),
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
        barrierColor: const Color.fromRGBO(0, 0, 0, 0.7),
        builder: (context) => StudyAssistantSheet(session: _chatSession),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.7),
      builder: (context) =>
          StudyAssistantSheet(session: _chatSession, isDialog: true),
    );
  }

  Widget _buildAssistantButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6600E599),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _openAssistant,
        tooltip: 'Ask the study assistant',
        backgroundColor: surfaceDark,
        foregroundColor: cyberGreen,
        elevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF00E599), width: 1.4),
        ),
        child: const Icon(Icons.smart_toy_rounded, size: 26),
      ),
    );
  }

  Widget _buildDockStatusPill() {
    final mitigatedCount = _mitigatedPages.length;
    final total = lessons.length;
    final isAllMitigated = mitigatedCount == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE60A101D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAllMitigated ? cyberGreenBorder : const Color(0xFF1E2D44),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isAllMitigated ? cyberGreen : threatAmber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isAllMitigated ? cyberGreen : threatAmber,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Text(
              isAllMitigated
                  ? 'FORENSICS COMPLETE · ALL 3 VECTORS MITIGATED'
                  : 'KILL CHAIN FORENSICS · $mitigatedCount/$total VECTORS ANALYZED',
              style: TextStyle(
                fontFamily: 'Arimo',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: isAllMitigated ? cyberGreen : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingDock() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xF20F172A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF243349), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x1F00E599),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _navButton(0, 'Home', 'Home', Icons.home_rounded),
          ),
          for (var i = 0; i < lessons.length; i++)
            Expanded(
              child: _navButton(
                i + 1,
                lessons[i].navLabel,
                lessons[i].title,
                lessons[i].icon,
              ),
            ),
        ],
      ),
    );
  }

  Widget _navButton(int page, String label, String tooltip, IconData icon) {
    final selected = _selectedPage == page;
    final isMitigated = page > 0 && _mitigatedPages.contains(page);
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed: () => _goTo(page),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: selected ? cyberGreen : textSecondary,
            overlayColor: const Color(0x1A00E599),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Arimo',
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? const Color(0x2E00E599) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? const Color(0x4D00E599) : Colors.transparent,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? cyberGreen
                          : (isMitigated ? const Color(0xFF6EE7B7) : textDim),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        color: selected
                            ? cyberGreen
                            : (isMitigated ? textPrimary : textSecondary),
                      ),
                    ),
                  ],
                ),
                if (isMitigated)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: cyberGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: cyberGreen, blurRadius: 4),
                        ],
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

  Widget _buildHome(bool isMobile, double titleSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome banner card
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 22),
          decoration: BoxDecoration(
            color: cardDark,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: _buildWelcomeHeader(isMobile, titleSize),
        ),
        SizedBox(height: isMobile ? 12 : 16),

        // Impact Metrics Stat Bar (single compact row)
        _buildImpactMetrics(isMobile),
        SizedBox(height: isMobile ? 12 : 16),

        // Unified Kill Chain & Lesson Vectors (single unified section, no duplicate lists)
        _buildUnifiedKillChainOverview(isMobile),
        SizedBox(height: isMobile ? 14 : 18),

        // Quick question
        const QuestionSection(),
        SizedBox(height: isMobile ? 16 : 22),
        const FooterSection(),
      ],
    );
  }

  Widget _buildUnifiedKillChainOverview(bool isMobile) {
    final mitigatedCount = _mitigatedPages.length;
    final total = lessons.length;
    final progress = total > 0 ? (mitigatedCount / total) : 0.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1F00E599),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x4D00E599)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timeline_rounded, size: 12, color: cyberGreen),
                    SizedBox(width: 5),
                    Text(
                      'KILL CHAIN FORENSICS',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: cyberGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Mitigated ($mitigatedCount/$total)',
                style: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: cyberGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Key Vulnerabilities & Defenses',
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: textPrimary,
                  ),
                ),
              ),
              if (!isMobile)
                const Text(
                  'Click to investigate vector',
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 11.5,
                    color: textDim,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFF16233B),
              valueColor: const AlwaysStoppedAnimation<Color>(cyberGreen),
            ),
          ),
          const SizedBox(height: 12),

          // Cards: high-density compact on mobile, side-by-side on desktop
          if (isMobile)
            Column(
              children: [
                for (var i = 0; i < lessons.length; i++) ...[
                  _buildCompactLessonRow(lessons[i], i + 1),
                  if (i < lessons.length - 1) const SizedBox(height: 7),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lessons.length; i++) ...[
                  Expanded(
                    child: _buildDesktopLessonCard(lessons[i], i + 1),
                  ),
                  if (i < lessons.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactLessonRow(Lesson lesson, int page) {
    final isMitigated = _mitigatedPages.contains(page);
    final (severityColor, severityBg) = switch (lesson.number) {
      '01' => (threatRed, threatRedBg),
      '02' => (threatAmber, threatAmberBg),
      _ => (cyberBlue, cyberBlueBg),
    };

    return Material(
      color: const Color(0xFF0F1728),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _goTo(page),
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0x1F00E599),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMitigated ? cyberGreenBorder : const Color(0xFF1E2D44),
              width: isMitigated ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMitigated ? cyberGreenDim : const Color(0xFF16233B),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isMitigated ? cyberGreenBorder : cardBorder,
                  ),
                ),
                child: Text(
                  lesson.number,
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isMitigated ? cyberGreen : textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lesson.title,
                            style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: severityBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lesson.stageName.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: severityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      lesson.tacticDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 11,
                        height: 1.3,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isMitigated ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                size: isMitigated ? 15 : 12,
                color: isMitigated ? cyberGreen : textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLessonCard(Lesson lesson, int page) {
    final isMitigated = _mitigatedPages.contains(page);
    final (severityColor, severityBg) = switch (lesson.number) {
      '01' => (threatRed, threatRedBg),
      '02' => (threatAmber, threatAmberBg),
      _ => (cyberBlue, cyberBlueBg),
    };

    return Material(
      color: const Color(0xFF0F1728),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _goTo(page),
        borderRadius: BorderRadius.circular(14),
        hoverColor: const Color(0x1F00E599),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMitigated ? cyberGreenBorder : const Color(0xFF1E2D44),
              width: isMitigated ? 1.2 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: severityBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      lesson.stageName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isMitigated ? cyberGreenDim : const Color(0xFF16233B),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isMitigated ? 'MITIGATED ✓' : 'ACTIVE ⚠️',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isMitigated ? cyberGreen : textDim,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(lesson.icon, size: 16, color: isMitigated ? cyberGreen : textPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lesson.tacticDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 12,
                  height: 1.35,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    isMitigated ? 'Review forensics' : 'Investigate vector',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isMitigated ? cyberGreen : const Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: isMitigated ? cyberGreen : const Color(0xFF60A5FA),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactMetrics(bool isMobile) {
    final metrics = [
      (
        '1/3',
        'US Patients',
        'Claims & scripts stalled',
        Icons.local_hospital_outlined,
        cyberGreen,
      ),
      (
        r'$22M+',
        'Ransom Extorted',
        'Total cost over \$2B',
        Icons.payments_outlined,
        threatAmber,
      ),
      (
        '100M+',
        'Records Breached',
        'Largest in US history',
        Icons.security_outlined,
        threatRed,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      metrics[i].$1,
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: isMobile ? 19 : 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.6,
                        height: 1.1,
                        color: metrics[i].$5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metrics[i].$2,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: isMobile ? 11 : 12.5,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: textPrimary,
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(height: 2),
                    Text(
                      metrics[i].$3,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 11,
                        height: 1.2,
                        color: textDim,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (i < metrics.length - 1)
              Container(
                height: isMobile ? 28 : 40,
                width: 1,
                color: const Color(0xFF1E293B),
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonKillChainStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1728),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < lessons.length; i++) ...[
              InkWell(
                onTap: () => _goTo(i + 1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedPage == (i + 1)
                              ? cyberGreen
                              : (_mitigatedPages.contains(i + 1)
                                  ? cyberGreenDim
                                  : const Color(0xFF16233B)),
                          border: Border.all(
                            color: _selectedPage == (i + 1)
                                ? cyberGreen
                                : (_mitigatedPages.contains(i + 1)
                                    ? cyberGreenBorder
                                    : const Color(0xFF263B60)),
                          ),
                        ),
                        child: _mitigatedPages.contains(i + 1) && _selectedPage != (i + 1)
                            ? const Icon(Icons.check, size: 12, color: cyberGreen)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontFamily: 'Arimo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedPage == (i + 1)
                                      ? bgDark
                                      : textSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lessons[i].navLabel,
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 12,
                          fontWeight: _selectedPage == (i + 1)
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedPage == (i + 1)
                              ? cyberGreen
                              : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < lessons.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF334155),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKillChainNextCard(bool isLastLesson, Lesson lesson) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLastLesson ? cyberGreenBorder : const Color(0xFF1E3558),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Icon(
                isLastLesson ? Icons.task_alt_rounded : Icons.trending_up_rounded,
                size: 16,
                color: isLastLesson ? cyberGreen : const Color(0xFF38BDF8),
              ),
              Text(
                isLastLesson
                    ? 'INCIDENT TRAJECTORY RESOLVED'
                    : 'NEXT THREAT IN INTRUSION PATH',
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: isLastLesson ? cyberGreen : const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLastLesson
                ? 'All three attack vectors have been mapped and mitigated. Test your knowledge with the security challenge.'
                : lesson.nextPhasePreview,
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isLastLesson) {
                  _goTo(0);
                } else {
                  _goTo(_selectedPage + 1);
                }
              },
              icon: Icon(
                isLastLesson ? Icons.quiz_rounded : Icons.arrow_forward_rounded,
                size: 16,
              ),
              label: Text(
                isLastLesson
                    ? 'Complete Forensics & Take Defense Quiz'
                    : 'Track Next Attack Vector ➔',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastLesson ? cyberGreen : const Color(0xFF1E293B),
                foregroundColor: isLastLesson ? bgDark : cyberGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isLastLesson ? cyberGreen : cyberGreenBorder,
                  ),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPage(bool isMobile) {
    final lesson = lessons[_selectedPage - 1];
    final isLastLesson = _selectedPage == lessons.length;
    final isMitigated = _mitigatedPages.contains(_selectedPage);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Kill Chain Stepper Navigation
            _buildLessonKillChainStepper(),
            const SizedBox(height: 14),

            // Top action bar: Back to home + Vector Status
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _goTo(0),
                  icon: const Icon(Icons.arrow_back_rounded, size: 17),
                  label: const Text('Back to home'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: cyberGreen,
                    overlayColor: const Color(0x1F00E599),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF1E293B)),
                    ),
                    splashFactory: NoSplash.splashFactory,
                    textStyle: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 13.5,
                      height: 1.4,
                      letterSpacing: 0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMitigated ? cyberGreenDim : const Color(0xFF1E1528),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMitigated ? cyberGreenBorder : const Color(0xFF4C161E),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMitigated ? Icons.verified_user_rounded : Icons.radar_rounded,
                        size: 13,
                        color: isMitigated ? cyberGreen : threatRed,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isMitigated ? 'VECTOR MITIGATED' : 'INVESTIGATING',
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: isMitigated ? cyberGreen : threatRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x2600E599),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x4D00E599)),
                ),
                child: Text(
                  '${lesson.stageName.toUpperCase()} · ${lesson.sectionLabel.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 11.5,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: cyberGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LessonCard(
              isMobile: isMobile,
              number: lesson.number,
              title: lesson.title,
              icon: lesson.icon,
              weakness: lesson.weakness,
              risk: lesson.risk,
              solution: lesson.solution,
            ),
            const SizedBox(height: 20),

            // In-Context Kill Chain Next Vector Card
            _buildKillChainNextCard(isLastLesson, lesson),
            const SizedBox(height: 16),

            // Secondary Lesson Nav Buttons (Previous / Next)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (_selectedPage > 1)
                  _lessonNavButton(
                    'Previous lesson',
                    Icons.arrow_back_rounded,
                    _selectedPage - 1,
                  )
                else
                  const SizedBox.shrink(),
                if (_selectedPage < lessons.length)
                  _lessonNavButton(
                    'Next lesson',
                    Icons.arrow_forward_rounded,
                    _selectedPage + 1,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 32),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _lessonNavButton(String label, IconData icon, int page) {
    return TextButton.icon(
      onPressed: () => _goTo(page),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: cyberGreen,
        overlayColor: const Color(0x1F00E599),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: cardBorder),
        ),
        splashFactory: NoSplash.splashFactory,
        textStyle: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 13,
          height: 1.4,
          letterSpacing: 0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isMobile, double titleSize) {
    final headerText = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: threatRedBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: threatRedBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x1AFF4D4F), blurRadius: 10),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: threatRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: threatRed, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Welcome · System Security and Threats',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isMobile ? 10 : 14),
        Text(
          'Change Healthcare\nRansomware Attack (2024)',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 22.0 : titleSize,
            height: 1.15,
            letterSpacing: -1.0,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Text(
          'Attackers used stolen login details to enter a system without MFA. '
          'The attack disrupted healthcare claims and payments.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 13.5 : 15.0,
            height: 1.45,
            color: textSecondary,
          ),
        ),
      ],
    );

    final gifWidth = isMobile ? 130.0 : 210.0;
    final gif = Semantics(
      image: true,
      label: 'Laptop hacking animation',
      child: Container(
        width: gifWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF243349), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              offset: Offset(0, 10),
              blurRadius: 28,
            ),
            BoxShadow(
              color: Color(0x1F00E599),
              offset: Offset(0, 0),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFF162032),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5F56),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFBD2E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF27C93F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'breach-telemetry.sh',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 10,
                        color: textDim,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              child: Image.asset(
                'laptop-hacking.gif',
                width: gifWidth,
                height: gifWidth * 0.78,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: headerText,
          ),
          const SizedBox(height: 12),
          gif,
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Row(
          children: [
            Expanded(child: headerText),
            const SizedBox(width: 32),
            gif,
          ],
        ),
      ),
    );
  }
}

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
      messages.add(
        ChatMessage(
          text: errorText,
          isUser: false,
        ),
      );
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
    if (kIsWeb) return Uri.base.resolve('/api/chat');
    return Uri.parse('https://healthcare-studycase.space/api/chat');
  }
}

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
    final panelHeight = math.min(680.0, availableHeight * 0.85);
    final panelWidth = widget.isDialog ? 440.0 : 560.0;
    final bottomSafeArea = media.viewInsets.bottom > 0
        ? 0.0
        : media.padding.bottom;

    final panel = Container(
      width: widget.isDialog ? panelWidth : double.infinity,
      height: panelHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: widget.isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(38, 63, 57, 0.18),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!widget.isDialog) _buildDragHandle(),
          _buildHeader(context),
          const Divider(height: 1, thickness: 1, color: borderColor),
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
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: dividerColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 22, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Study assistant',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: solutionBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: solutionBorderColor),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ask about the Change Healthcare attack',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: mutedTextColor,
                  ),
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
              minimumSize: const Size(36, 36),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      children: [
        for (final message in messages) _MessageBubble(message: message),
        if (showSuggestions) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in _suggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: sending ? null : () => _sendMessage(suggestion),
                  backgroundColor: const Color(0xFF131D30),
                  side: const BorderSide(color: cardBorder),
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
                    color: cyberGreen,
                    fontWeight: FontWeight.w500,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        if (sending) ...[const SizedBox(height: 12), const _ThinkingBubble()],
      ],
    );
  }

  Widget _buildComposer(double bottomSafeArea) {
    final sending = widget.session.sending;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + bottomSafeArea),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: cardBorder)),
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
                fillColor: const Color(0xFF131D30),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: cyberGreen, width: 1.5),
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
                backgroundColor: cyberGreen,
                foregroundColor: const Color(0xFF090D16),
                disabledBackgroundColor: const Color(0xFF13232C),
                disabledForegroundColor: textDim,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF090D16),
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
      height: 1.55,
      color: textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF16233B),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFF263B60)),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: cyberGreen),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1E293B) : const Color(0xFF131D30),
                border: Border.all(
                  color: isUser ? const Color(0xFF334155) : cardBorder,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: _buildFormattedContent(message.text, baseStyle, isUser),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String rawText, TextStyle baseStyle, bool isUser) {
    if (isUser) {
      return Text(rawText.trim(), style: baseStyle);
    }

    // Completely strip any asterisks (*, **, ***) and normalize bullets and whitespace
    final text = rawText
        .replaceAll(RegExp(r'^\s*[-*•]\s*', multiLine: true), '• ')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'^(•\s*)+', multiLine: true), '• ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    final titleRegex = RegExp(r'^(•\s*|\d+\.\s*)([^:：\n]+[:：])(.*)$');

    // If it's a plain single-line response with no list labels, return standard Text
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
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: cyberGreen,
          ),
        ));
        spans.add(TextSpan(text: match.group(3), style: baseStyle));
      } else {
        spans.add(TextSpan(text: line, style: baseStyle));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 2, right: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF16233B),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFF263B60)),
          ),
          child: const Icon(Icons.smart_toy_rounded, size: 16, color: cyberGreen),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131D30),
            border: Border.all(color: cardBorder),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cyberGreen,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Analyzing threats…',
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.isMobile,
    required this.number,
    required this.title,
    required this.icon,
    required this.weakness,
    required this.risk,
    required this.solution,
  });

  final bool isMobile;
  final String number;
  final String title;
  final IconData icon;
  final String weakness;
  final String risk;
  final String solution;

  @override
  Widget build(BuildContext context) {
    final padding = isMobile ? 20.0 : 26.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cardDark,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 6),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: numberBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorderGlow),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: cyberGreen,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 21,
                          height: 1.25,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: cyberGreenDim,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: cyberGreenBorder),
                      ),
                      child: Icon(icon, size: 18, color: cyberGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 1. Weakness Block
          _buildDetailBlock(
            label: 'Weakness',
            content: weakness,
            icon: Icons.warning_amber_rounded,
            badgeBg: weaknessBgColor,
            badgeBorder: weaknessBorderColor,
            badgeText: weaknessTextColor,
          ),
          const SizedBox(height: 14),

          // 2. Risk Block
          _buildDetailBlock(
            label: 'Risk',
            content: risk,
            icon: Icons.crisis_alert_rounded,
            badgeBg: riskBgColor,
            badgeBorder: riskBorderColor,
            badgeText: riskTextColor,
          ),
          const SizedBox(height: 14),

          // 3. Solution Block
          _buildDetailBlock(
            label: 'Solution',
            content: solution,
            icon: Icons.verified_user_rounded,
            badgeBg: solutionBgColor,
            badgeBorder: solutionBorderColor,
            badgeText: solutionTextColor,
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBlock({
    required String label,
    required String content,
    required IconData icon,
    required Color badgeBg,
    required Color badgeBorder,
    required Color badgeText,
    bool isHighlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF0C1A2E) : const Color(0xFF0D1626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? cyberGreenBorder : const Color(0xFF1E2D44),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: badgeText),
                    const SizedBox(width: 5),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14.5,
              height: 1.6,
              color: Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionSection extends StatefulWidget {
  const QuestionSection({super.key});

  @override
  State<QuestionSection> createState() => _QuestionSectionState();
}

class _QuestionSectionState extends State<QuestionSection> {
  // -1: not chosen, 0: chosen 'No' (correct), 1: chosen 'Yes' (incorrect)
  int _selectedOption = -1;
  bool _isOpen = false;

  void _chooseOption(int option) {
    setState(() {
      _selectedOption = option;
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        color: const Color(0xFF0D172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2F4D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick question',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 19,
                  height: 1.3,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Transform.translate(
                offset: const Offset(0, -1),
                child: Image.asset(
                  'assets/images/thought-balloon-3d.png',
                  width: 22,
                  height: 22,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'A hospital’s old server still works. '
            'Should it skip security updates?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 15.5,
              height: 1.55,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          // Interactive choice pills
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildChoiceButton(
                label: '❌ No (Always patch)',
                isSelected: _selectedOption == 0,
                isCorrect: true,
                onTap: () => _chooseOption(0),
              ),
              _buildChoiceButton(
                label: '⚠️ Yes (If it still functions)',
                isSelected: _selectedOption == 1,
                isCorrect: false,
                onTap: () => _chooseOption(1),
              ),
            ],
          ),

          if (_selectedOption != -1) ...[
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedOption == 0 ? solutionBgColor : weaknessBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedOption == 0
                      ? solutionBorderColor
                      : weaknessBorderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedOption == 0
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: _selectedOption == 0
                        ? solutionTextColor
                        : weaknessTextColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _selectedOption == 0
                          ? 'Spot on! Operational does not equal secure.'
                          : 'Watch out: Legacy unpatched systems are the #1 attack vector.',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedOption == 0
                            ? solutionTextColor
                            : weaknessTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => setState(() => _isOpen = !_isOpen),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: cyberGreen,
                        overlayColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        textStyle: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          height: 1.6,
                          letterSpacing: 0,
                          fontWeight: FontWeight.bold,
                          color: cyberGreen,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DisclosureMarker(expanded: _isOpen),
                          const Text(
                            'Show answer',
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 14,
                              height: 1.6,
                              fontWeight: FontWeight.bold,
                              color: cyberGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isOpen) ...[
                    const SizedBox(height: 14),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'No.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                ' Working does not mean secure. Test updates using '
                                'sample claims, check the results, and prepare a backup '
                                'and rollback plan before updating.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 14,
                        height: 1.6,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required bool isCorrect,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? (isCorrect ? solutionBgColor : weaknessBgColor)
          : const Color(0xFF131D30),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isCorrect ? solutionTextColor : weaknessTextColor)
                  : cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isCorrect ? solutionTextColor : weaknessTextColor)
                  : textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class ShowAnswerButton extends StatefulWidget {
  const ShowAnswerButton({super.key});

  @override
  State<ShowAnswerButton> createState() => _ShowAnswerButtonState();
}

class _ShowAnswerButtonState extends State<ShowAnswerButton> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => setState(() => _isOpen = !_isOpen),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: cyberGreen,
              overlayColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              textStyle: const TextStyle(
                fontFamily: 'Arimo',
                fontSize: 14,
                height: 1.6,
                letterSpacing: 0,
                fontWeight: FontWeight.bold,
                color: cyberGreen,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DisclosureMarker(expanded: _isOpen),
                const Text(
                  'Show answer',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    color: cyberGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isOpen) ...[
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'No.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                ),
                TextSpan(
                  text:
                      ' Working does not mean secure. Test updates using '
                      'sample claims, check the results, and prepare a backup '
                      'and rollback plan before updating.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.6, color: textSecondary),
          ),
          const SizedBox(height: 15),
        ],
      ],
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  static const _footerStyle = TextStyle(
    fontSize: 12,
    height: 1.6,
    color: textDim,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Learn more: ', style: _footerStyle),
            _link(
              'CISA security guide',
              'https://www.cisa.gov/stopransomware/ransomware-guide',
            ),
            const Text(' · ', style: _footerStyle),
            _link(
              'NIST patching guide',
              'https://csrc.nist.gov/pubs/sp/1800/31/final',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'System Fundamental · Extra learning content',
          textAlign: TextAlign.center,
          style: _footerStyle,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _link(String label, String url) {
    return TextButton(
      onPressed: () => _openLink(url),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: cyberGreen,
        overlayColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        textStyle: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 12,
          height: 1.6,
          letterSpacing: 0,
          color: cyberGreen,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          height: 1.6,
          color: cyberGreen,
          decoration: TextDecoration.underline,
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

/// The disclosure triangle Chrome draws inside a native `summary` element.
///
/// The summary text is centred as a group, so the marker occupies a fixed
/// 15px slot (a 7px triangle plus an 8px gap). When the answer is open the
/// triangle points down instead of right.
class _DisclosureMarker extends StatelessWidget {
  const _DisclosureMarker({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 10,
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomPaint(
          size: expanded ? const Size(9, 8) : const Size(7, 9),
          painter: _DisclosureTrianglePainter(expanded: expanded),
        ),
      ),
    );
  }
}

class _DisclosureTrianglePainter extends CustomPainter {
  const _DisclosureTrianglePainter({required this.expanded});

  final bool expanded;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = cyberGreen;
    final path = Path();
    if (expanded) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DisclosureTrianglePainter oldDelegate) =>
      oldDelegate.expanded != expanded;
}
