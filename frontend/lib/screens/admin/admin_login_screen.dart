import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'admin_shell.dart';

/// Member 6 - Admin Login.
///
/// A deliberately separate door from the fan app: it only accepts accounts whose
/// `role` is `admin`, and it never shows sign-up, Google or "forgot password"
/// links because administrator accounts are provisioned, not self-served.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // An admin who is already signed in skips this screen entirely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AdminProvider>().signedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AdminProvider>();
    final response = await provider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      adminToast(context, 'Welcome back, ${provider.adminName}');
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AdminShell()));
    } else {
      adminToast(
        context,
        (response['message'] ?? 'Admin login failed').toString(),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return AdminThemeScope(
      child: Scaffold(
        backgroundColor: AdminTheme.bg,
        body: Container(
          decoration: BoxDecoration(gradient: AdminTheme.heroGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBrandMark(),
                        const SizedBox(height: 26),
                        Text(
                          'Admin Portal',
                          style: GoogleFonts.outfit(
                            color: AdminTheme.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Restricted access - administrators only',
                          style: TextStyle(
                            color: AdminTheme.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildCard(provider),
                        const SizedBox(height: 22),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandMark() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            gradient: AdminTheme.brandGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AdminTheme.primary.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'FANDOM VERSE',
          style: GoogleFonts.outfit(
            color: AdminTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AdminProvider provider) {
    return AdminPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign in to continue',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            style: TextStyle(color: AdminTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Admin Email',
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 19),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            style: TextStyle(color: AdminTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password is too short';
              return null;
            },
          ),
          const SizedBox(height: 22),
          AdminPrimaryButton(
            label: 'Login',
            icon: Icons.login_rounded,
            expand: true,
            loading: provider.busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: AdminTheme.textMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Every sign-in attempt is written to the security log.',
                  style: GoogleFonts.inter(
                    color: AdminTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: Icon(
        Icons.arrow_back_rounded,
        size: 16,
        color: AdminTheme.textSecondary,
      ),
      label: Text(
        'Back to Fandom Verse',
        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
      ),
    );
  }
}
