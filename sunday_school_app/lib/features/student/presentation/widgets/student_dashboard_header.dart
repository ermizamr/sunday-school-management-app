import 'package:flutter/material.dart';

import 'gospel_verses.dart';

/// Hero header for the student dashboard.
///
/// Features a continuous, seamless horizontal gradient from deep Sunday school
/// blue on the left to pure white on the far right. The school logo is
/// rendered as a large, bold visual element on the right that gracefully overflows
/// and trims at the card edges, while the student details and untrimmed daily
/// Gospel verse remain clearly legible on the blue gradient.
class StudentDashboardHeader extends StatelessWidget {
  const StudentDashboardHeader({
    super.key,
    required this.greeting,
    required this.displayName,
    required this.avatarInitial,
    required this.ethiopianDateString,
    required this.isAmharic,
    this.gradeName,
    this.academicYearName,
    this.dailyVerse,
  });

  final String greeting;
  final String displayName;
  final String avatarInitial;
  final String ethiopianDateString;
  final bool isAmharic;
  final String? gradeName;
  final String? academicYearName;

  /// Verse of the day rendered inside the header. When null, the header only
  /// shows the student identity block.
  final GospelVerse? dailyVerse;

  // Single continuous, seamless LinearGradient without any harsh step overlays:
  // Starts with Sunday school sky-700 on the left, allows white to begin early
  // through sky-400 and sky-200, and finishes softly into pure white at the right.
  static const LinearGradient _headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      Color(0xFF0284C7), // Sunday school deep sky blue
      Color(0xFF0EA5E9), // Vibrant azure
      Color(0xFF7DD3FC), // Soft sky blue (white begins early)
      Color(0xFFE0F2FE), // Ice blue (blue finishes late)
      Color(0xFFFFFFFF), // Pure white at the far right edge for logo contrast
    ],
    stops: <double>[0.0, 0.25, 0.50, 0.75, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: isAmharic ? 'የተማሪ ዳሽቦርድ' : 'Student dashboard',
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: _headerGradient),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth;
              final bool compact = width < 420;
              final double horizontalPadding = compact ? 16 : 20;

              // Logo sized so top (cross) and bottom (open book) are fully shown, shifted near to the right
              final double logoRightOffset = -(width * 0.10);

              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // 1. Logo fitted vertically so top and bottom are fully shown
                  Positioned(
                    top: 10,
                    bottom: 14,
                    right: logoRightOffset,
                    child: IgnorePointer(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: <Color>[
                              Color(0x00FFFFFF), // fully transparent on the left edge
                              Color(0x55FFFFFF), // gentle soft fade
                              Color(0xFFFFFFFF), // full opacity towards the right
                            ],
                            stops: <double>[0.0, 0.22, 0.55],
                          ).createShader(bounds);
                        },
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.centerRight,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),

                  // 2. Foreground content: student identity details & daily verse
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: (width * 0.78).clamp(240.0, 520.0),
                            ),
                            child: _IdentityBlock(
                              greeting: greeting,
                              displayName: displayName,
                              avatarInitial: avatarInitial,
                              ethiopianDateString: ethiopianDateString,
                              isAmharic: isAmharic,
                              gradeName: gradeName,
                              academicYearName: academicYearName,
                            ),
                          ),
                        ),
                        if (dailyVerse != null) ...<Widget>[
                          const SizedBox(height: 18),
                          _HeaderVerse(
                            verse: dailyVerse!,
                            isAmharic: isAmharic,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.greeting,
    required this.displayName,
    required this.avatarInitial,
    required this.ethiopianDateString,
    required this.isAmharic,
    this.gradeName,
    this.academicYearName,
  });

  final String greeting;
  final String displayName;
  final String avatarInitial;
  final String ethiopianDateString;
  final bool isAmharic;
  final String? gradeName;
  final String? academicYearName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _HeaderPill(
              icon: Icons.calendar_today_rounded,
              label: ethiopianDateString,
            ),
            if (academicYearName != null && academicYearName!.trim().isNotEmpty)
              _HeaderPill(
                icon: Icons.school_rounded,
                label: academicYearName!.trim(),
                background: const Color(0x33F59E0B),
                border: const Color(0x66FCD34D),
                foreground: const Color(0xFFFEF3C7),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xE6FFFFFF),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      shadows: <Shadow>[
                        Shadow(color: Color(0x33000000), blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.15,
                      shadows: <Shadow>[
                        Shadow(color: Color(0x40000000), blurRadius: 8),
                      ],
                    ),
                  ),
                  if (gradeName != null &&
                      gradeName!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    _GradeBadge(label: gradeName!.trim()),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _AvatarBadge(initial: avatarInitial),
          ],
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    this.background = const Color(0x33FFFFFF),
    this.border = const Color(0x4DFFFFFF),
    this.foreground = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0x52FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF38BDF8), Color(0xFF0369A1)],
        ),
        border: Border.all(color: const Color(0xFFFDE68A), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Glassy verse panel that sits inside the header, over the gradient.
///
/// The verse deliberately has no `maxLines` and no `overflow`, so long
/// passages wrap and the header grows instead of trimming the text.
class _HeaderVerse extends StatelessWidget {
  const _HeaderVerse({
    required this.verse,
    required this.isAmharic,
  });

  final GospelVerse verse;
  final bool isAmharic;

  static const Color _gold = Color(0xFFFCD34D);
  static const Color _goldSoft = Color(0xFFFDE68A);

  @override
  Widget build(BuildContext context) {
    final String text = verse.text(isAmharic);
    final String quoted = isAmharic ? '«$text»' : '“$text”';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xE60369A1), Color(0xD9075985)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x3DFFFFFF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x33FCD34D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x66FCD34D)),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 18,
                  color: _gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAmharic ? 'የዕለቱ ወንጌል' : 'GOSPEL VERSE OF THE DAY',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _goldSoft,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quoted,
            softWrap: true,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 14.5,
              height: isAmharic ? 1.85 : 1.55,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: isAmharic ? 0.1 : 0.05,
              shadows: const <Shadow>[
                Shadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x26FCD34D),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x4DFCD34D)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.bookmark_rounded,
                    size: 13,
                    color: _gold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    verse.reference(isAmharic),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _goldSoft,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
