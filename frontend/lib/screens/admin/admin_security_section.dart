import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Security Settings.
///
/// Password change, the platform security switches and the admin login audit
/// trail. Backed by /api/admin/security.
class AdminSecuritySection extends StatefulWidget {
  const AdminSecuritySection({super.key});

  @override
  State<AdminSecuritySection> createState() => _AdminSecuritySectionState();
}

class _AdminSecuritySectionState extends State<AdminSecuritySection> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _history = [];

  bool _loading = true;
  bool _saving = false;
  bool _changing = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AdminService.security();

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _settings = Map<String, dynamic>.from(response['settings'] ?? {});
        _stats = Map<String, dynamic>.from(response['stats'] ?? {});
        _history = (response['loginHistory'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load security settings.')
            .toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      _settings = {..._settings, key: value};
      _saving = true;
    });

    final response = await AdminService.saveSecuritySettings({key: value});

    if (!mounted) return;
    setState(() => _saving = false);

    if (response['success'] != true) {
      setState(() => _settings = {..._settings, key: !value});
      adminToast(
        context,
        (response['message'] ?? 'Could not save the setting.').toString(),
        error: true,
      );
      return;
    }

    _settings = Map<String, dynamic>.from(response['settings'] ?? _settings);
    adminToast(context, '${_labelFor(key)} updated.');
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _changing = true);

    final response = await AdminService.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (!mounted) return;
    setState(() => _changing = false);

    if (response['success'] == true) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      adminToast(context, 'Password updated successfully.');
      _load();
    } else {
      adminToast(
        context,
        (response['message'] ?? 'Could not update the password.').toString(),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AdminLoader(label: 'Loading security settings...');
    }
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Security Settings',
            subtitle: 'Protect the admin account and the platform',
            icon: Icons.security_rounded,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminPill(
                label: '${_num(_stats['admins'])} administrator(s)',
                color: AdminTheme.primary,
                icon: Icons.admin_panel_settings_rounded,
              ),
              AdminPill(
                label: '${_num(_stats['failedLogins'])} failed logins',
                color: AdminTheme.amber,
                icon: Icons.gpp_bad_rounded,
              ),
              AdminPill(
                label: '${_num(_stats['securityEvents'])} security events',
                color: AdminTheme.red,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 940;

              if (stacked) {
                return Column(
                  children: [
                    _buildPasswordCard(),
                    const SizedBox(height: 18),
                    _buildSettingsCard(),
                    const SizedBox(height: 18),
                    _buildHistoryCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 400,
                    child: Column(
                      children: [
                        _buildPasswordCard(),
                        const SizedBox(height: 18),
                        _buildHistoryCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: _buildSettingsCard()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    final provider = context.watch<AdminProvider>();

    return AdminPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.key_rounded,
                  size: 17,
                  color: AdminTheme.violet,
                ),
                const SizedBox(width: 9),
                Text(
                  'Update Password',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Signed in as ${provider.adminEmail}',
              style: TextStyle(
                color: AdminTheme.textMuted,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _currentController,
              obscureText: _obscure,
              style: TextStyle(color: AdminTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Current password is required'
                  : null,
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _newController,
              obscureText: _obscure,
              style: TextStyle(color: AdminTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'New password is required';
                if (v.length < 6) return 'Use at least 6 characters';
                if (v == _currentController.text) {
                  return 'New password must be different';
                }
                return null;
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              style: TextStyle(color: AdminTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.check_circle_outline_rounded, size: 18),
              ),
              validator: (v) {
                if (v != _newController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),
            AdminPrimaryButton(
              label: 'Update Password',
              icon: Icons.save_rounded,
              loading: _changing,
              expand: true,
              onPressed: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 17, color: AdminTheme.cyan),
              const SizedBox(width: 9),
              Text(
                'Platform Security',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_saving)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AdminTheme.indigo,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildToggle(
            key: 'login_alerts',
            icon: Icons.notifications_active_rounded,
            title: 'Login Alerts',
            subtitle: 'Record and surface every admin sign-in attempt.',
            color: AdminTheme.cyan,
          ),
          _buildToggle(
            key: 'two_factor',
            icon: Icons.verified_user_rounded,
            title: 'Two-Factor Authentication (2FA)',
            subtitle:
                'Require a second factor the next time an admin signs in.',
            color: AdminTheme.green,
          ),
          Divider(color: AdminTheme.border, height: 26),
          _buildToggle(
            key: 'registration',
            icon: Icons.person_add_alt_1_rounded,
            title: 'Open Registration',
            subtitle: 'Allow new fans to create accounts from the app.',
            color: AdminTheme.indigo,
          ),
          _buildToggle(
            key: 'maintenance',
            icon: Icons.construction_rounded,
            title: 'Maintenance Mode',
            subtitle: 'Flag the platform as under maintenance.',
            color: AdminTheme.amber,
          ),
          _buildToggle(
            key: 'auto_backup',
            icon: Icons.backup_rounded,
            title: 'Automatic Backups',
            subtitle: 'Keep a rolling copy of the SQLite database.',
            color: AdminTheme.violet,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final value = _toBool(_settings[key]);

    return SwitchListTile(
      value: value,
      onChanged: _saving ? null : (next) => _toggle(key, next),
      contentPadding: EdgeInsets.zero,
      activeThumbColor: color,
      secondary: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AdminTheme.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AdminTheme.textMuted, fontSize: 11.5),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 17,
                color: AdminTheme.amber,
              ),
              const SizedBox(width: 9),
              Text(
                'Admin Login Activity',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_history.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No login activity recorded yet.',
                style: TextStyle(color: AdminTheme.textMuted, fontSize: 12.5),
              ),
            )
          else
            ..._history.map((entry) {
              final level = (entry['level'] ?? 'info').toString();
              final color = AdminTheme.forLevel(level);

              return AdminListRow(
                title: (entry['action'] ?? '')
                    .toString()
                    .replaceAll('_', ' ')
                    .toUpperCase(),
                subtitle: (entry['details'] ?? entry['admin_email'] ?? '')
                    .toString(),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    level.toLowerCase() == 'warn'
                        ? Icons.gpp_bad_rounded
                        : Icons.login_rounded,
                    size: 16,
                    color: color,
                  ),
                ),
                trailing: Text(
                  (entry['ago'] ?? '').toString(),
                  style: TextStyle(
                    color: AdminTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case 'login_alerts':
        return 'Login alerts';
      case 'two_factor':
        return 'Two-factor authentication';
      case 'registration':
        return 'Open registration';
      case 'maintenance':
        return 'Maintenance mode';
      case 'auto_backup':
        return 'Automatic backups';
      default:
        return 'Setting';
    }
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    if (value == null) return 0;
    return num.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }
}
