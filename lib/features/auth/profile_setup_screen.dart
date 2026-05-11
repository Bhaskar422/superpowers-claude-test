import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import 'auth_errors.dart';
import 'profile_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nativeLanguage = TextEditingController();
  String? _level;
  int _goalMinutes = 10;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nativeLanguage.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    if (_nativeLanguage.text.trim().isEmpty || _level == null) {
      setState(() =>
          _error = 'Please enter your native language and select an English level');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).upsertProfile(
            userId: user.id,
            email: user.email ?? '',
            nativeLanguage: _nativeLanguage.text.trim(),
            englishLevel: _level!,
            dailyGoalMinutes: _goalMinutes,
          );
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _levelButton(String value, String label) {
    final selected = _level == value;
    return ChoiceChip(
      key: Key('profile_level_$value'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _level = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome!')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tell us a little about you.'),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profile_native_language'),
              controller: _nativeLanguage,
              decoration: const InputDecoration(labelText: 'Native language'),
            ),
            const SizedBox(height: 16),
            const Text('English level'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _levelButton('beginner', 'Beginner'),
                _levelButton('intermediate', 'Intermediate'),
                _levelButton('advanced', 'Advanced'),
              ],
            ),
            const SizedBox(height: 16),
            Text('Daily goal: $_goalMinutes minutes'),
            Slider(
              value: _goalMinutes.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '$_goalMinutes min',
              onChanged: (v) => setState(() => _goalMinutes = v.round()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('profile_submit'),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
