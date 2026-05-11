import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env.dart';
import 'core/supabase_client.dart';
import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await AppSupabase.initialize();
  runApp(const ProviderScope(child: EnglishCoachApp()));
}

class EnglishCoachApp extends StatefulWidget {
  const EnglishCoachApp({super.key});

  @override
  State<EnglishCoachApp> createState() => _EnglishCoachAppState();
}

class _EnglishCoachAppState extends State<EnglishCoachApp> {
  // No-op until Task 13 wires auth and profile state changes into router refresh.
  final _refresh = ValueNotifier<Object?>(null);
  late final _router = buildRouter(refreshListenable: _refresh);

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'English Coach',
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
