import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';
import 'package:sunday_school_app/main.dart';

void main() {
  testWidgets('App renders role selection', (WidgetTester tester) async {
    await tester.pumpWidget(const SundaySchoolApp());

    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.roleSelectionTitle), findsOneWidget);
    expect(find.text(l10n.roleStudent), findsOneWidget);
    expect(find.text(l10n.roleServant), findsOneWidget);
  });
}
