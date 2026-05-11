import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class EnglishCoachApp extends ConsumerStatefulWidget {
  const EnglishCoachApp({super.key});

  @override
  ConsumerState<EnglishCoachApp> createState() => _EnglishCoachAppState();
}

class _EnglishCoachAppState extends ConsumerState<EnglishCoachApp> {
  late final GoRouter _router = buildAppRouter(ref);

  @override
  void dispose() {
    _router.dispose();
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
