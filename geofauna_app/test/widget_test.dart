// Smoke test for the EcoGuía design system. The full app needs Firebase, which
// isn't initialised in unit tests, so we verify the theme + a shared widget
// render correctly in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geofauna/theme/app_theme.dart';
import 'package:geofauna/widgets/eco_widgets.dart';

void main() {
  testWidgets('EcoChip renders within the EcoGuía theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(child: EcoChip('Estable', tone: ChipTone.emerald)),
        ),
      ),
    );

    // Chip labels are upper-cased by the widget.
    expect(find.text('ESTABLE'), findsOneWidget);
  });
}
