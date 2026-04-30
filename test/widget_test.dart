import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/main.dart';

void main() {
  testWidgets('MyApp renders a provided home widget', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(
          home: SizedBox.expand(
            child: Center(
              child: Text('Smoke Test'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Smoke Test'), findsOneWidget);
  });
}
