import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? nativeLanguage;
  final String? englishLevel;
  final int dailyGoalMinutes;
  final bool isPaid;
  final int trialSessionsUsed;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.nativeLanguage,
    required this.englishLevel,
    required this.dailyGoalMinutes,
    required this.isPaid,
    required this.trialSessionsUsed,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        email: m['email'] as String,
        displayName: m['display_name'] as String?,
        nativeLanguage: m['native_language'] as String?,
        englishLevel: m['english_level'] as String?,
        dailyGoalMinutes: m['daily_goal_minutes'] as int,
        isPaid: m['is_paid'] as bool,
        trialSessionsUsed: m['trial_sessions_used'] as int,
      );

  bool get isComplete =>
      nativeLanguage != null && englishLevel != null;
}

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client})
      : _client = client ?? AppSupabase.client;

  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  Future<void> upsertProfile({
    required String userId,
    required String email,
    String? displayName,
    required String nativeLanguage,
    required String englishLevel,
    required int dailyGoalMinutes,
  }) async {
    await _client.from('users').upsert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'native_language': nativeLanguage,
      'english_level': englishLevel,
      'daily_goal_minutes': dailyGoalMinutes,
    });
  }
}
