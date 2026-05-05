import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().register(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        );
    if (!mounted) return;
    if (ok) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Start journaling trades and unlocking AI-powered insights.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Already have one? ', style: TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Sign in')),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name (optional)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lossSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.loss),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.loss))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: auth.busy ? null : _submit,
              child: auth.busy
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
