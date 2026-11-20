import 'package:flutter/material.dart';

/// Hero header for the student dashboard.
///
/// The right half of the card carries the school logo as a watermark. A
/// [ShaderMask] with [BlendMode.dstIn] fades the logo in from the centre of
/// the card towards the right edge, so the artwork never replaces the header
/// background or competes with the student's details.
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
  });

  final String greeting;
  final String displayName;
  final String avatarInitial;
  final String ethiopianDateString;
  final bool isAmharic;
  final String? gradeName;
  final String? academicYearName;

  static const _headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF075985), // sky-800
      Color(0xFF0369A1), // sky-700
      Color(0xFF0C4A6E), // sky-900
    ],
    stops: <double>[0.0, 0.55, 1.0],
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
              return Stack(
                children: <Widget>[
                  // Soft halo behind the logo keeps the blue artwork legible on
                  // the blue header without washing out the left-hand copy.
                  Positioned(
                    top: -56,
                    right: -36,
                    width: 280,
                    height: 280,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              Color(0x2EFFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Logo watermark: right half only, faded in from the left.
                  Positioned(
                    top: -24,
                    right: -constraints.maxWidth * 0.03,
                    bottom: -20,
                    width: constraints.maxWidth * 0.62,
                    child: IgnorePointer(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: <Color>[
                              Color(0x00FFFFFF), // fully transparent
                              Color(0x1FFFFFFF),
                              Color(0x7AFFFFFF),
                              Color(0xE6FFFFFF), // clearly visible at the edge
                            ],
                            stops: <double>[0.0, 0.32, 0.68, 1.0],
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

                  // Foreground content sits above the watermark.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Date + academic year
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            _HeaderPill(
                              icon: Icons.calendar_today_rounded,
                              label: ethiopianDateString,
                            ),
                            if (academicYearName != null &&
                                academicYearName!.trim().isNotEmpty)
                              _HeaderPill(
                                icon: Icons.school_rounded,
                                label: academicYearName!.trim(),
                                background: const Color(0x3DF59E0B),
                                border: const Color(0x80FCD34D),
                                foreground: const Color(0xFFFEF3C7),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Greeting, name, grade and avatar
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
                                      fontSize: 13.5,
                                      color: Color(0xE6FFFFFF),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (gradeName != null &&
                                      gradeName!.trim().isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 7),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x26FFFFFF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0x33FFFFFF),
                                        ),
                                      ),
                                      child: Text(
                                        gradeName!.trim(),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFFE0F2FE),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _AvatarBadge(initial: avatarInitial),
                          ],
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
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

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x40FFFFFF),
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
