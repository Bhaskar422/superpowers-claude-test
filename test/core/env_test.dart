import 'package:flutter_test/flutter_test.dart';
import 'package:english_coach/core/env.dart';

void main() {
  tearDown(Env.resetForTesting);

  test('Env.supabaseUrl returns a non-empty value when initialized', () async {
    await Env.load(fromString: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon-test-key
''');
    expect(Env.supabaseUrl, 'https://example.supabase.co');
    expect(Env.supabaseAnonKey, 'anon-test-key');
  });

  test('reading a key before load() throws StateError', () {
    expect(() => Env.supabaseUrl, throwsStateError);
  });

  test('missing env var throws StateError', () async {
    await Env.load(fromString: 'SUPABASE_URL=https://example.supabase.co\n');
    expect(() => Env.supabaseAnonKey, throwsStateError);
  });
}
