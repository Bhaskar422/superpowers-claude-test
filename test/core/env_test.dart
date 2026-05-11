import 'package:flutter_test/flutter_test.dart';
import 'package:english_coach/core/env.dart';

void main() {
  test('Env.supabaseUrl returns a non-empty value when initialized', () async {
    await Env.load(fromString: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon-test-key
''');
    expect(Env.supabaseUrl, 'https://example.supabase.co');
    expect(Env.supabaseAnonKey, 'anon-test-key');
  });
}
