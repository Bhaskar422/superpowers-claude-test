import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await AppSupabase.initialize();
  runApp(const ProviderScope(child: BootstrapApp()));
}

class BootstrapApp extends StatelessWidget {
  const BootstrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'English Coach',
      home: Scaffold(
        body: Center(child: Text('Bootstrap OK')),
      ),
    );
  }
}
