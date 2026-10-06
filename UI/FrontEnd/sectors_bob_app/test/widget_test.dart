// Smoke test for the BOB app root.
//
// Boots the app and confirms it reaches the splash screen without throwing,
// replacing the default Flutter counter test that referenced a non-existent
// MyApp widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sectors_bob_app/main.dart';

void main() {
  testWidgets('BobApp boots and renders a MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: BobApp()));

    // First frame renders without exceptions and mounts the router's app.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
