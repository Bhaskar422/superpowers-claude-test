import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_coach/core/router.dart';

void main() {
  testWidgets('router starts at /home and shows the home shell with bottom nav',
      (tester) async {
    final router = buildRouter(refreshListenable: ValueNotifier(null));
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('tapping the Sessions nav item navigates to /sessions',
      (tester) async {
    final router = buildRouter(refreshListenable: ValueNotifier(null));
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the Sessions tab inside the BottomNavigationBar.
    final navBar = find.byType(BottomNavigationBar);
    final sessionsLabelInNav = find.descendant(
      of: navBar,
      matching: find.text('Sessions'),
    );
    await tester.tap(sessionsLabelInNav);
    await tester.pumpAndSettle();

    // The Sessions placeholder screen renders its own centered "Sessions" text
    // in the body, separate from the nav-bar label.
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/sessions');
    expect(find.text('Sessions'), findsAtLeastNWidgets(2)); // nav label + body
  });
}
