import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harness_app/main.dart';

void main() {
  testWidgets('app builds and shows the root MaterialApp', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MyHomePage), findsOneWidget);
  });
}
