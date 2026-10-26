import 'package:flutter/material.dart';
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

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth <= 720;
    final titleSize = (screenWidth * 0.042).clamp(28.0, 40.0).toDouble();

    return Scaffold(
      backgroundColor: bgColor,
      body: DefaultTextStyle(
        // Material's default text style adds letter spacing, which makes the
        // text wrap differently from the original CSS. Keep it at zero.
        style: const TextStyle(
          fontFamily: 'Arimo',
          fontSize: 16,
          height: 1.6,
          letterSpacing: 0,
          color: textColor,
        ),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 18 : 24,
                  vertical: isMobile ? 30 : 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: _buildHeader(isMobile, titleSize),
                      ),
                    ),
                    SizedBox(height: isMobile ? 25 : 38),

                    // Three lesson cards
                    _buildCards(isMobile),

                    // Empty paragraph in the HTML adds this space
                    const SizedBox(height: 16),

                    // Question and answer
                    const QuestionSection(),
                    const SizedBox(height: 25),

                    // Footer
                    const FooterSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, double titleSize) {
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
            'System Security and Threats',
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

  Widget _buildCards(bool isMobile) {
    final cards = [
      LessonCard(
        isMobile: isMobile,
        number: '01',
        title: 'Missing MFA',
        icon: Icons.smartphone,
        weakness:
            'The affected remote-access portal only required login details.',
        risk: 'A stolen password could let an attacker enter.',
        solution: 'Require MFA, such as a password plus a security key.',
      ),
      LessonCard(
        isMobile: isMobile,
        number: '02',
        title: 'Outdated Systems',
        icon: Icons.dns,
        weakness:
            'Old, unsupported software may stop receiving security updates.',
        risk: 'Attackers could exploit known security flaws.',
        solution: 'Test and install updates. Replace unsupported systems.',
      ),
      LessonCard(
        isMobile: isMobile,
        number: '03',
        title: 'Poor Network Separation',
        icon: Icons.hub,
        weakness:
            'Unnecessary connections can let attackers reach other systems.',
        risk: 'One infected device could lead to a wider outage.',
        solution: 'Separate important systems and allow only necessary access.',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 18),
          cards[1],
          const SizedBox(height: 18),
          cards[2],
        ],
      );
    }

    // IntrinsicHeight makes all three cards the same height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 18),
          Expanded(child: cards[1]),
          const SizedBox(width: 18),
          Expanded(child: cards[2]),
        ],
      ),
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
      // The extra 2px at the bottom makes up for Flutter rounding text
      // line heights down to whole pixels.
      padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 14),
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
