import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Flutter version of the original HTML case study.
// The colours, spacing and font sizes below come straight from the HTML/CSS.

const bgColor = Color(0xFFF5F7F4);
const textColor = Color(0xFF263F39);
const mutedTextColor = Color(0xFF61716A);
const tagBgColor = Color(0xFFDFEAD9);
const tagTextColor = Color(0xFF34573A);
const borderColor = Color(0xFFDFE5DD);
const numberBgColor = Color(0xFFE5EFDF);
const dividerColor = Color(0xFFE6EBE3);
const questionBgColor = Color(0xFFE6EEDF);
const footerTextColor = Color(0xFF68766D);
const linkColor = Color(0xFF3D624B);

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
  });

  final String number;
  final String title;
  final String navLabel;
  final String sectionLabel;
  final IconData icon;
  final String weakness;
  final String risk;
  final String solution;
}

const lessons = [
  Lesson(
    number: '01',
    title: 'Missing MFA',
    navLabel: 'MFA',
    sectionLabel: 'First vulnerability',
    icon: Icons.smartphone,
    weakness: 'The affected remote-access portal only required login details.',
    risk: 'A stolen password could let an attacker enter.',
    solution: 'Require MFA, such as a password plus a security key.',
  ),
  Lesson(
    number: '02',
    title: 'Outdated Systems',
    navLabel: 'Updates',
    sectionLabel: 'Second vulnerability',
    icon: Icons.dns,
    weakness: 'Old, unsupported software may stop receiving security updates.',
    risk: 'Attackers could exploit known security flaws.',
    solution: 'Test and install updates. Replace unsupported systems.',
  ),
  Lesson(
    number: '03',
    title: 'Poor Network Separation',
    navLabel: 'Network',
    sectionLabel: 'Third vulnerability',
    icon: Icons.hub,
    weakness: 'Unnecessary connections can let attackers reach other systems.',
    risk: 'One infected device could lead to a wider outage.',
    solution: 'Separate important systems and allow only necessary access.',
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
        fontFamily: 'Arimo',
        scaffoldBackgroundColor: bgColor,
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
      bottomNavigationBar: _buildNavBar(),
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
        barrierColor: const Color.fromRGBO(38, 63, 57, 0.35),
        builder: (context) => StudyAssistantSheet(session: _chatSession),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          StudyAssistantSheet(session: _chatSession, isDialog: true),
    );
  }

  Widget _buildAssistantButton() {
    return FloatingActionButton(
      onPressed: _openAssistant,
      tooltip: 'Ask the study assistant',
      backgroundColor: textColor,
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.smart_toy, size: 27),
    );
  }

  Widget _buildNavBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          // The bottomNavigationBar slot passes loose height constraints,
          // so Center must shrink-wrap the 64px tab row.
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SizedBox(
              height: 64,
              child: Row(
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(int page, String label, String tooltip, IconData icon) {
    final selected = _selectedPage == page;
    final color = selected ? textColor : footerTextColor;
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed: () => _goTo(page),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            minimumSize: const Size(0, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: color,
            overlayColor: selected
                ? const Color.fromRGBO(38, 63, 57, 0.06)
                : const Color.fromRGBO(38, 63, 57, 0.04),
            shape: const RoundedRectangleBorder(),
            textStyle: const TextStyle(
              fontFamily: 'Arimo',
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? tagTextColor : footerTextColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
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
          padding: EdgeInsets.all(isMobile ? 20 : 23),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _buildWelcomeHeader(isMobile, titleSize),
        ),
        const SizedBox(height: 18),

        // The quick question is part of the home page too.
        const QuestionSection(),
        const SizedBox(height: 25),
        const FooterSection(),
      ],
    );
  }

  Widget _buildLessonPage(bool isMobile) {
    final lesson = lessons[_selectedPage - 1];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _goTo(0),
                icon: const Icon(Icons.arrow_back, size: 17),
                label: const Text('Back to home'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: linkColor,
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  textStyle: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 13,
                    height: 1.6,
                    letterSpacing: 0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lesson.sectionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    color: tagTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            LessonCard(
              isMobile: isMobile,
              number: lesson.number,
              title: lesson.title,
              icon: lesson.icon,
              weakness: lesson.weakness,
              risk: lesson.risk,
              solution: lesson.solution,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (_selectedPage > 1)
                  _lessonNavButton(
                    'Previous lesson',
                    Icons.arrow_back,
                    _selectedPage - 1,
                  )
                else
                  const SizedBox.shrink(),
                if (_selectedPage < lessons.length)
                  _lessonNavButton(
                    'Next lesson',
                    Icons.arrow_forward,
                    _selectedPage + 1,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 25),
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
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: linkColor,
        overlayColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        textStyle: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 13,
          height: 1.6,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: tagBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Welcome · System Security and Threats',
            style: TextStyle(fontSize: 12, height: 1.6, color: tagTextColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Change Healthcare\nRansomware Attack (2024)',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: titleSize,
            height: 1.15,
            letterSpacing: -1.2,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Attackers used stolen login details to enter a system without MFA. '
          'The attack disrupted healthcare claims and payments.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 15,
            height: 1.55,
            color: mutedTextColor,
          ),
        ),
      ],
    );

    final gifSize = isMobile ? 140.0 : 185.0;
    final gif = Semantics(
      image: true,
      label: 'Laptop hacking animation',
      child: Container(
        width: gifSize,
        height: gifSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(38, 63, 57, 0.1),
              offset: Offset(0, 6),
              blurRadius: 18,
            ),
          ],
          image: const DecorationImage(
            image: AssetImage('laptop-hacking.gif'),
            fit: BoxFit.cover,
          ),
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
          const SizedBox(height: 20),
          gif,
        ],
      );
    }

    // 580 (text) + 36 (gap) + 185 (image) = 801
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 801),
        child: Row(
          children: [
            Expanded(child: headerText),
            const SizedBox(width: 36),
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
    throw Exception(
      'Set AI_CHAT_ENDPOINT to the deployed /api/chat URL when running on '
      'mobile, for example: '
      '--dart-define=AI_CHAT_ENDPOINT=https://healthcare-studycase.space/api/chat',
    );
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
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy, size: 20, color: tagTextColor),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Study assistant',
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.25,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ask about the Change Healthcare attack',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
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
              foregroundColor: mutedTextColor,
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
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  labelStyle: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    height: 1.3,
                    color: linkColor,
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
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomSafeArea),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor)),
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
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Ask about the case study…',
                hintStyle: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 14,
                  color: footerTextColor,
                ),
                filled: true,
                fillColor: bgColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: tagTextColor, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: sending ? null : () => _sendMessage(),
              tooltip: 'Send',
              style: IconButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: tagBgColor,
                disabledForegroundColor: tagTextColor,
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
                        color: tagTextColor,
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
      color: isUser ? Colors.white : textColor,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: BoxDecoration(
                color: tagBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, size: 14, color: tagTextColor),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? textColor : Colors.white,
                border: isUser ? null : Border.all(color: borderColor),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 16),
                ),
                boxShadow: isUser
                    ? null
                    : const [
                        BoxShadow(
                          color: Color.fromRGBO(38, 63, 57, 0.04),
                          offset: Offset(0, 2),
                          blurRadius: 4,
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
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
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
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(top: 2, right: 8),
          decoration: BoxDecoration(
            color: tagBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.smart_toy, size: 14, color: tagTextColor),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: tagTextColor,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Thinking…',
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 13,
                  height: 1.4,
                  color: mutedTextColor,
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
    final padding = isMobile ? 20.0 : 23.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: numberBgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(icon, size: 18, color: tagTextColor),
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 13),
          _paragraph('Weakness:', weakness),
          const SizedBox(height: 12),
          _paragraph('Risk:', risk),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: _paragraph('Solution:', solution, icon: Icons.lightbulb),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String label, String text, {IconData? icon}) {
    final paragraph = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' $text'),
        ],
      ),
      style: const TextStyle(fontSize: 14, height: 1.6, color: textColor),
    );

    if (icon == null) {
      return paragraph;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(icon, size: 16, color: tagTextColor),
        ),
        const SizedBox(width: 5),
        Expanded(child: paragraph),
      ],
    );
  }
}

class QuestionSection extends StatelessWidget {
  const QuestionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 2px more at the bottom offsets the 2px the summary moves up below,
      // keeping the closed card the same height as the HTML version.
      padding: const EdgeInsets.fromLTRB(23, 23, 23, 25),
      decoration: BoxDecoration(
        color: questionBgColor,
        borderRadius: BorderRadius.circular(14),
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
                  fontSize: 19,
                  height: 1.3,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              // The original page uses the colour 💭 emoji. Flutter Web only
              // has a black-and-white fallback, so use the picture instead.
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
          const SizedBox(height: 13),
          const Text(
            'A hospital’s old server still works. '
            'Should it skip security updates?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
          ),
          // 17px instead of the collapsed CSS 16px to balance Flutter's
          // rounded line heights. The extra 2px at the bottom of the card
          // keeps the section boundary aligned with the HTML.
          const SizedBox(height: 17),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: const ShowAnswerButton(),
            ),
          ),
        ],
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
              foregroundColor: textColor,
              overlayColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              textStyle: const TextStyle(
                fontFamily: 'Arimo',
                fontSize: 14,
                height: 1.6,
                letterSpacing: 0,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // A 7x9 triangle plus an 8px gap, matching the native
                // disclosure marker used by the HTML <summary> element.
                _DisclosureMarker(expanded: _isOpen),
                const Text(
                  'Show answer',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
            style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
          ),
          // This, plus the extra bottom padding on the section, keeps the
          // open card the same height as the HTML version after Flutter
          // rounds the text line heights.
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
    color: footerTextColor,
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
        foregroundColor: linkColor,
        overlayColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        textStyle: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 12,
          height: 1.6,
          letterSpacing: 0,
          color: linkColor,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          height: 1.6,
          color: linkColor,
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
    final paint = Paint()..color = textColor;
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
