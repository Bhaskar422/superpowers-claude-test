import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts an error thrown by AuthRepository into a user-facing string.
///
/// Auth screens display whatever this returns directly to the user, so the
/// goal is plain language without SDK internals or stack traces.
String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.trim();
    if (msg.isEmpty) return 'Sign-in failed. Please try again.';
    return msg;
  }
  return 'Something went wrong. Please try again.';
}
