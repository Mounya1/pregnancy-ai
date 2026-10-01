import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/gradient_button.dart';
import 'auth_shell.dart';
import 'forgot_password_screen.dart';

/// The unlock screen. An account already exists on this device, so the only
/// question is the password.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _password = TextEditingController();
  final _email = TextEditingController();
  String? _error;

  /// E.g. "Your account is confirmed" when arriving from the code screen.
  String? _notice;

  @override
  void initState() {
    super.initState();
    // Set here rather than as a `late final` with a context lookup: a lazy
    // initialiser can first run inside dispose(), and reading an inherited
    // widget from a deactivated element throws.
    final auth = context.read<AuthController>();
    _email.text = auth.account?.email ?? '';
    _notice = auth.takeSignInNotice();
  }

  @override
  void dispose() {
    _password.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final failure = await auth.signIn(_password.text, email: _email.text);
    if (!mounted) return;
    setState(() => _error = failure);
    if (failure == null) _password.clear();
  }

  /// No server means no reset link. The only real option is wiping the device
  /// copy and starting again, so say that plainly instead of offering a
  /// "recovery" that cannot exist.
  Future<void> _forgotPassword() async {
    final auth = context.read<AuthController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forgot your password?'),
        content: const Text(
          'This account only exists on this phone, so there is no reset email '
          'and no way to verify who you are.\n\n'
          'The only way back in is to start over, which erases your profile, '
          'saved foods, reminders, medical reports, and baby records from this '
          'device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.palette.avoid),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase and start over'),
          ),
        ],
      ),
    );

    if (confirmed == true) await auth.deleteAccountAndData();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = context.watch<AuthController>();
    // No name when this browser has never seen the account - someone who
    // arrived here from "Already have an account?" would otherwise be
    // greeted as "Welcome back, there".
    final name = auth.account?.firstName;

    return AuthShell(
      title: name == null ? 'Welcome back' : 'Welcome back, $name',
      subtitle: auth.isCloud
          ? 'Sign in with your email and password to pick up where you left off.'
          : 'Enter your password to unlock your plans and records.',
      showBabyFigure: true,
      children: [
        if (_notice != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.safeSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: p.safe),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _notice!,
                    style: TextStyle(fontSize: 12, height: 1.4, color: p.safe),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        // Cloud accounts are keyed on email, and the same login works on any
        // device - so the address has to be editable, not assumed from
        // whatever this phone happens to remember.
        if (auth.isCloud) ...[
          AuthField(
            controller: _email,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AuthField(
          controller: _password,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          autofocus: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _error,
          onSubmitted: auth.busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.xxl),
        GradientButton(
          label: auth.busy ? 'Unlocking...' : 'Sign in',
          icon: Icons.lock_open_rounded,
          loading: auth.busy,
          onPressed: auth.busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: auth.busy
              ? null
              : () {
                  if (auth.isCloud) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(initialEmail: _email.text),
                      ),
                    );
                  } else {
                    _forgotPassword();
                  }
                },
          style: TextButton.styleFrom(foregroundColor: p.textSecondary),
          child: const Text('Forgot password?', style: TextStyle(fontSize: 12.5)),
        ),
        // Device-only builds have one account per phone, so there is nothing
        // to switch to - see AuthSwitch.
        if (auth.isCloud)
          AuthSwitch(
            prompt: "Don't have an account?",
            action: 'Create one',
            onPressed: auth.busy ? null : auth.showSignUp,
          ),
      ],
    );
  }
}
