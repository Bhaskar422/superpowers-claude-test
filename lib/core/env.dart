import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static bool _loaded = false;

  static Future<void> load({String? fromString}) async {
    if (fromString != null) {
      dotenv.testLoad(fileInput: fromString);
    } else {
      await dotenv.load(fileName: '.env');
    }
    _loaded = true;
  }

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    if (!_loaded) {
      throw StateError('Env.load() must be called before reading $key');
    }
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) {
      throw StateError('Missing env var: $key');
    }
    return v;
  }
}
