import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chust_one_academy/app/app.dart';

void main() {
  testWidgets('App boots to splash screen without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChustOneApp()));
    await tester.pump();
    // Let the splash screen's animation and its 2s navigation delay finish.
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
  });
}
