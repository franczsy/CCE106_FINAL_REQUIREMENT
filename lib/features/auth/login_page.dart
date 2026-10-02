import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';

class LoginPage extends StatefulWidget {
  final bool staffOnly;

  const LoginPage({super.key, this.staffOnly = false});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Enter your email and password.');
      return;
    }
    if (supabaseAnonKey.isEmpty) {
      _showMessage('Supabase is not configured for this app.');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (widget.staffOnly && !_isAdmin(response.user)) {
        await Supabase.instance.client.auth.signOut();
        _showMessage('This account does not have admin access.');
        return;
      }

      if (!mounted) return;
      context.go(widget.staffOnly ? '/admin' : '/student');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isAdmin(User? user) {
    final role = user?.appMetadata['role'];
    return role?.toString().toLowerCase() == 'admin';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to menu',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant_menu, size: 64),
                  const SizedBox(height: 12),
                  Text('University of Mindanao', style: Theme.of(context).textTheme.headlineMedium),
                  Text(widget.staffOnly ? 'Staff account sign in' : 'Student account sign in'),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : login,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: Text(_loading
                          ? 'SIGNING IN...'
                          : (widget.staffOnly ? 'STAFF LOGIN' : 'STUDENT SIGN IN')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!widget.staffOnly)
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create student account'),
                    ),
                  const SizedBox(height: 10),
                  const Text('Students can create an account or continue ordering without signing in.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
