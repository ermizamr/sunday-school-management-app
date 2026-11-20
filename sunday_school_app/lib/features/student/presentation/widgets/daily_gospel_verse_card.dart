import 'package:flutter/material.dart';

import 'gospel_verses.dart';

/// Warm, editorial card that presents the Gospel verse of the day.
///
/// The verse is intentionally rendered without `maxLines` or `overflow` so it
/// is always shown in full, even for long passages such as Luke 6:38.
class DailyGospelVerseCard extends StatelessWidget {
  const DailyGospelVerseCard({
    super.key,
    required this.verse,
    required this.isAmharic,
  });

  final GospelVerse verse;
  final bool isAmharic;

  static const _ink = Color(0xFF1F2937);
  static const _mutedInk = Color(0xFF64748B);
  static const _gold = Color(0xFFB45309);
  static const _goldDeep = Color(0xFF92400E);
  static const _goldLine = Color(0xFFE7CFA0);
  static const _paper = Color(0xFFFFFCF5);

  @override
  Widget build(BuildContext context) {
    final primaryText = verse.text(isAmharic);
    final secondaryText = isAmharic ? verse.english : verse.amharic;

    final primaryStyle = TextStyle(
      fontSize: 17,
      height: isAmharic ? 1.9 : 1.7,
      fontWeight: FontWeight.w600,
      color: _ink,
      letterSpacing: isAmharic ? 0.1 : 0.05,
    );

    final secondaryStyle = TextStyle(
      fontSize: 13.5,
      height: isAmharic ? 1.7 : 1.6,
      fontWeight: FontWeight.w400,
      fontStyle: isAmharic ? FontStyle.normal : FontStyle.italic,
      color: _mutedInk,
      letterSpacing: 0.05,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${verse.referenceAm}. ${verse.amharic} '
          '${verse.referenceEn}. ${verse.english}',
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFFFFEFB), _paper, Color(0xFFFFF8E9)],
            stops: <double>[0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEAD9B0)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x140B4F6C),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x0AD4A853),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: <Widget>[
              // Oversized closing quote watermark in the top-right corner.
              Positioned(
                top: -26,
                right: 8,
                child: IgnorePointer(
                  child: Text(
                    '”',
                    style: TextStyle(
                      fontSize: 104,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD4A853).withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Eyebrow
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFFFDE68A),
                                Color(0xFFF5C451),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE7CFA0)),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 19,
                            color: _goldDeep,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                isAmharic
                                    ? 'የዕለቱ ወንጌል'
                                    : 'GOSPEL VERSE OF THE DAY',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _goldDeep,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAmharic
                                    ? 'ለዛሬ የተመረጠ ቃል'
                                    : 'A fresh word for today',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFA16207),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFF3D9A4)),
                          ),
                          child: Text(
                            isAmharic ? 'ዕለታዊ' : 'DAILY',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _goldDeep,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Primary verse — never truncated.
                    Text(
                      '“$primaryText”',
                      style: primaryStyle,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 10),

                    // Secondary language, set apart with a quiet gold rule.
                    Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: _goldLine, width: 2),
                        ),
                      ),
                      child: Text(
                        secondaryText,
                        style: secondaryStyle,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reference footer
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFEFE2C4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: _gold.withValues(alpha: 0.75),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFEFE2C4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF3D7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _goldLine),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.bookmark_rounded,
                                size: 13,
                                color: _goldDeep,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                verse.reference(isAmharic),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _goldDeep,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isAmharic ? 'ወንጌል' : 'Gospel',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _mutedInk.withValues(alpha: 0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
