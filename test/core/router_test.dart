import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_coach/core/router.dart';

void main() {
  testWidgets('router starts at /home and shows the home shell with bottom nav',
      (tester) async {
    final router = buildRouter(refreshListenable: ValueNotifier(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
