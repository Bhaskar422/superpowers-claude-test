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
  final _refresh = ValueNotifier<Object?>(null);
  late final _router = buildRouter(refreshListenable: _refresh);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'English Coach',
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
