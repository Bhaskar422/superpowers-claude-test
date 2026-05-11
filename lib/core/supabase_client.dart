import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Single consistent import point for the Supabase client.
/// Feature code should depend on `AppSupabase.client` rather than
/// reaching for `Supabase.instance.client` directly, so the wrapper
/// can grow seams for testing or instrumentation without churn.
class AppSupabase {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
