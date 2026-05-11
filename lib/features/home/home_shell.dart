import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    ('/home',     Icons.home,        'Home'),
    ('/sessions', Icons.mic,         'Sessions'),
    ('/progress', Icons.show_chart,  'Progress'),
    ('/profile',  Icons.person,      'Profile'),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => context.go(_tabs[i].$1),
        items: _tabs
            .map((t) => BottomNavigationBarItem(icon: Icon(t.$2), label: t.$3))
            .toList(),
      ),
    );
  }
}
