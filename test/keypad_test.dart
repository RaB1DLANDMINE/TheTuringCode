import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/keypad_widget.dart';

void main() {
  testWidgets('KeypadWidget renders all buttons', (WidgetTester tester) async {
    String pressedKey = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KeypadWidget(onKeyPressed: (key) => pressedKey = key),
      ),
    ));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('#'), findsOneWidget);

    await tester.tap(find.text('5'));
    expect(pressedKey, '5');
  });
}
