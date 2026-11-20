import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunday_school_app/features/student/presentation/widgets/daily_gospel_verse_card.dart';
import 'package:sunday_school_app/features/student/presentation/widgets/gospel_verses.dart';
import 'package:sunday_school_app/features/student/presentation/widgets/student_dashboard_header.dart';

void main() {
  group('gospel verse catalogue', () {
    test('has at least 30 bilingual verses from all four Gospels', () {
      expect(gospelVerses.length, greaterThanOrEqualTo(30));

      for (final verse in gospelVerses) {
        expect(verse.amharic.trim(), isNotEmpty);
        expect(verse.english.trim(), isNotEmpty);
        expect(verse.referenceAm, startsWith(verse.book.amharicName));
        expect(verse.referenceEn, startsWith(verse.book.englishName));
      }

      expect(
        gospelVerses.map((GospelVerse verse) => verse.book).toSet(),
        GospelBook.values.toSet(),
      );
    });
  });

  group('daily selection', () {
    test('is stable for a whole calendar day', () {
      final morning = gospelVerseForDate(DateTime(2026, 11, 20, 6));
      final evening = gospelVerseForDate(DateTime(2026, 11, 20, 22, 45));

      expect(evening.referenceEn, morning.referenceEn);
    });

    test('advances to a different verse on the next day', () {
      final today = gospelVerseForDate(DateTime(2026, 11, 20));
      final tomorrow = gospelVerseForDate(DateTime(2026, 11, 21));

      expect(tomorrow.referenceEn, isNot(today.referenceEn));
    });

    test('cycles through the complete catalogue', () {
      final start = DateTime(2026, 11, 20);
      final first = gospelVerseForDate(start);
      final afterFullCycle = gospelVerseForDate(
        start.add(Duration(days: gospelVerses.length)),
      );

      expect(afterFullCycle.referenceEn, first.referenceEn);
    });
  });

  testWidgets('verse card shows the untrimmed text and reference chip', (
    WidgetTester tester,
  ) async {
    final verse = gospelVerses.firstWhere(
      (GospelVerse verse) => verse.referenceEn == 'Luke 6:38',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DailyGospelVerseCard(verse: verse, isAmharic: false),
          ),
        ),
      ),
    );

    expect(find.textContaining('Give, and it will be given'), findsOneWidget);
    expect(find.text('Luke 6:38'), findsOneWidget);
  });

  testWidgets('header fits a narrow phone with daily verse without overflow', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final verse = gospelVerses.firstWhere(
      (GospelVerse verse) => verse.referenceEn == 'John 14:27',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentDashboardHeader(
              greeting: 'እንደ ምን አደሩ',
              displayName: 'አበበ ከበደ',
              avatarInitial: 'አ',
              ethiopianDateString: '📅 ጥቅምት 11, 2018 ዓ.ም',
              isAmharic: true,
              gradeName: 'ደረጃ 5',
              academicYearName: '2018 ዓ.ም',
              dailyVerse: verse,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ሰላምን እተውላችኋለሁ'), findsOneWidget);
  });
}
