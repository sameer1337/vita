import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/daily_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/smoking_provider.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../root.dart';

/// Account + cloud sync. Optional — Vita works fully offline; signing in just
/// lets the user back up and restore their data across devices.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _status = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SyncException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _authenticate() => _run(() async {
        final auth = Supabase.instance.client.auth;
        final email = _emailCtrl.text.trim();
        final password = _passwordCtrl.text;
        if (_isSignUp) {
          await auth.signUp(email: email, password: password);
        } else {
          await auth.signInWithPassword(email: email, password: password);
        }
        if (mounted) setState(() => _status = 'Signed in as $email');
      });

  Future<void> _backup() => _run(() async {
        await SyncService().backup();
        if (mounted) setState(() => _status = 'Backed up to the cloud ☁️');
      });

  Future<void> _restore() => _run(() async {
        final plan = await SyncService().restore();
        // Refresh every provider that reads from local storage.
        ref.invalidate(onboardingProvider);
        ref.invalidate(dailyProvider);
        ref.invalidate(smokingProvider);
        ref.invalidate(reminderProvider);
        if (!mounted) return;
        if (plan != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const VitaRoot()),
            (r) => false,
          );
        } else {
          setState(() => _status = 'Restored your data from the cloud');
        }
      });

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Account & sync'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Vita works fully offline. Sign in to back up your plan and '
              'progress and restore them on another device.',
              style: TextStyle(color: Colors.white60, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (user == null) _signedOut() else _signedIn(user.email ?? ''),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _banner(_error!, const Color(0xFFE0566E)),
            ],
            if (_status != null) ...[
              const SizedBox(height: 16),
              _banner(_status!, AppTheme.sage),
            ],
          ],
        ),
      ),
    );
  }

  Widget _signedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(_emailCtrl, 'Email', TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(_passwordCtrl, 'Password', TextInputType.visiblePassword,
            obscure: true),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.sage,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _busy ? null : _authenticate,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isSignUp ? 'Create account' : 'Sign in'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _isSignUp = !_isSignUp),
          child: Text(
            _isSignUp
                ? 'Already have an account? Sign in'
                : "New to Vita? Create an account",
            style: const TextStyle(color: AppTheme.sageLight),
          ),
        ),
      ],
    );
  }

  Widget _signedIn(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.sage,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Signed in',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(email,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.sage,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _busy ? null : _backup,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Back up to cloud'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _busy ? null : _restore,
          icon: const Icon(Icons.cloud_download_outlined),
          label: const Text('Restore from cloud'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(() => Supabase.instance.client.auth.signOut()),
          child: const Text('Sign out',
              style: TextStyle(color: Colors.white54)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Backup overwrites the cloud copy; restore overwrites this device. '
          'Most recent action wins.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String hint, TextInputType type,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: AppTheme.darkSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _banner(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
