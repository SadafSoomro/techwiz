import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Manage Users.
///
/// Search + role/status filtering, inline activate/deactivate, delete, and an
/// add/edit form. All of it is backed by /api/admin/users.
class AdminUsersSection extends StatefulWidget {
  const AdminUsersSection({super.key});

  @override
  State<AdminUsersSection> createState() => _AdminUsersSectionState();
}

class _AdminUsersSectionState extends State<AdminUsersSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _pagination = {};

  String _role = '';
  String _status = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AdminService.users(
      search: _searchController.text.trim(),
      role: _role,
      status: _status,
      page: page,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _users = (response['users'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _summary = Map<String, dynamic>.from(response['summary'] ?? {});
        _pagination = Map<String, dynamic>.from(response['pagination'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load users.').toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? user}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserFormDialog(user: user),
    );
    if (saved == true) _load(page: _page);
  }

  int get _page => (_pagination['page'] as num?)?.toInt() ?? 1;
  int get _pages => (_pagination['pages'] as num?)?.toInt() ?? 1;
  int get _total => (_pagination['total'] as num?)?.toInt() ?? 0;

  Future<void> _toggleStatus(Map<String, dynamic> user, bool isActive) async {
    final name = (user['name'] ?? user['email'] ?? 'this user').toString();

    final confirmed = await adminConfirm(
      context,
      title: isActive ? 'Activate user?' : 'Deactivate user?',
      message: isActive
          ? '$name will be able to sign in to Fandom Verse again.'
          : '$name will be blocked from signing in. Their data is kept.',
      confirmLabel: isActive ? 'Activate' : 'Deactivate',
      destructive: !isActive,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.setUserStatus(_id(user), isActive);
    if (!mounted) return;

    adminToast(
      context,
      (response['message'] ?? 'Done').toString(),
      error: response['success'] != true,
    );
    _load(page: _page);
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final name = (user['name'] ?? user['email'] ?? 'this user').toString();

    final confirmed = await adminConfirm(
      context,
      title: 'Delete user permanently?',
      message:
          'This removes $name and their posts, bookmarks, cart and wishlist. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.deleteUser(_id(user));
    if (!mounted) return;

    adminToast(
      context,
      (response['message'] ?? 'Deleted').toString(),
      error: response['success'] != true,
    );
    _load(page: 1);
  }

  Future<void> _showDetail(Map<String, dynamic> user) async {
    final response = await AdminService.userDetail(_id(user));
    if (!mounted) return;

    if (response['success'] != true) {
      adminToast(
        context,
        (response['message'] ?? 'Could not load the user.').toString(),
        error: true,
      );
      return;
    }

    final detail = Map<String, dynamic>.from(response['user'] ?? {});
    final stats = Map<String, dynamic>.from(response['stats'] ?? {});

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            AdminAvatar(name: (detail['name'] ?? '?').toString(), size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (detail['name'] ?? 'Unnamed').toString(),
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    (detail['email'] ?? '').toString(),
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminPill(
                    label: (detail['role'] ?? 'user').toString(),
                    color: AdminTheme.forRole(
                      (detail['role'] ?? 'user').toString(),
                    ),
                  ),
                  AdminPill(
                    label: _toBool(detail['is_active'])
                        ? 'active'
                        : 'deactivated',
                    color: _toBool(detail['is_active'])
                        ? AdminTheme.green
                        : AdminTheme.red,
                  ),
                  AdminPill(
                    label: _toBool(detail['verified'])
                        ? 'verified'
                        : 'unverified',
                    color: _toBool(detail['verified'])
                        ? AdminTheme.cyan
                        : AdminTheme.amber,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: AdminTheme.border),
              const SizedBox(height: 10),
              Wrap(
                spacing: 26,
                runSpacing: 14,
                children: [
                  AdminMiniStat(
                    label: 'posts',
                    value: '${stats['posts'] ?? 0}',
                  ),
                  AdminMiniStat(
                    label: 'orders',
                    value: '${stats['orders'] ?? 0}',
                  ),
                  AdminMiniStat(
                    label: 'bookmarks',
                    value: '${stats['bookmarks'] ?? 0}',
                  ),
                  AdminMiniStat(
                    label: 'tickets',
                    value: '${stats['tickets'] ?? 0}',
                    color: AdminTheme.cyan,
                  ),
                  AdminMiniStat(
                    label: 'points',
                    value: '${detail['points'] ?? 0}',
                    color: AdminTheme.amber,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _detailLine('Phone', (detail['phone'] ?? '-').toString()),
              _detailLine('Joined', (detail['created_at'] ?? '-').toString()),
              _detailLine(
                'Last login',
                (detail['last_login_at'] ?? 'never').toString(),
              ),
              _detailLine('Bio', (detail['bio'] ?? '-').toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AdminTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openForm(user: detail);
            },
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(color: AdminTheme.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Manage Users',
            subtitle:
                '${AdminTheme.compact(_total)} matching of '
                '${AdminTheme.compact(_num(_summary['total']))} registered accounts',
            icon: Icons.people_alt_rounded,
            action: AdminPrimaryButton(
              label: 'Add User',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: 18),
          _buildSummaryChips(),
          const SizedBox(height: 16),
          _buildToolbar(),
          const SizedBox(height: 14),
          Expanded(child: _buildList()),
          if (!_loading && _error == null)
            AdminPager(
              page: _page,
              pages: _pages,
              total: _total,
              onPage: (page) => _load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        AdminPill(
          label: '${_num(_summary['total'])} total',
          color: AdminTheme.indigo,
          icon: Icons.groups_rounded,
        ),
        AdminPill(
          label: '${_num(_summary['admins'])} admins',
          color: AdminTheme.primary,
          icon: Icons.admin_panel_settings_rounded,
        ),
        AdminPill(
          label: '${_num(_summary['editors'])} editors',
          color: AdminTheme.cyan,
          icon: Icons.edit_rounded,
        ),
        AdminPill(
          label: '${_num(_summary['blocked'])} blocked',
          color: AdminTheme.red,
          icon: Icons.block_rounded,
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSearchField(
          controller: _searchController,
          hint: 'Search users by name, email or phone...',
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 12),
        AdminFilterChips(
          options: const {
            '': 'All roles',
            'admin': 'Admins',
            'editor': 'Editors',
            'user': 'Fans',
          },
          selected: _role,
          onSelected: (value) {
            setState(() => _role = value);
            _load();
          },
        ),
        const SizedBox(height: 8),
        AdminFilterChips(
          options: const {
            '': 'Any status',
            'active': 'Active',
            'blocked': 'Deactivated',
            'verified': 'Verified',
            'unverified': 'Unverified',
          },
          selected: _status,
          onSelected: (value) {
            setState(() => _status = value);
            _load();
          },
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) return const AdminLoader(label: 'Loading users...');
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }
    if (_users.isEmpty) {
      return const AdminEmptyState(
        message: 'No users match these filters.',
        icon: Icons.person_search_rounded,
      );
    }

    return AdminPanel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _users.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AdminTheme.border,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final user = _users[index];
          final isActive = _toBool(user['is_active']);

          return AdminListRow(
            title: (user['name'] ?? 'Unnamed').toString(),
            subtitle:
                '${user['email'] ?? ''}'
                '${user['joined_ago'] != null ? '  -  joined ${user['joined_ago']}' : ''}',
            leading: AdminAvatar(
              name: (user['name'] ?? '?').toString(),
              color: AdminTheme.forRole((user['role'] ?? 'user').toString()),
            ),
            onTap: () => _showDetail(user),
            pills: [
              AdminPill(
                label: (user['role'] ?? 'user').toString(),
                color: AdminTheme.forRole((user['role'] ?? 'user').toString()),
              ),
              AdminPill(
                label: isActive ? 'active' : 'deactivated',
                color: isActive ? AdminTheme.green : AdminTheme.red,
              ),
              if (!_toBool(user['verified']))
                AdminPill(label: 'unverified', color: AdminTheme.amber),
            ],
            menu: PopupMenuButton<String>(
              color: AdminTheme.surfaceAlt,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AdminTheme.textMuted,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _openForm(user: user);
                    break;
                  case 'toggle':
                    _toggleStatus(user, !isActive);
                    break;
                  case 'delete':
                    _delete(user);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded, size: 17),
                    title: Text('Edit user', style: TextStyle(fontSize: 13)),
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      size: 17,
                      color: isActive ? AdminTheme.red : AdminTheme.green,
                    ),
                    title: Text(
                      isActive ? 'Deactivate' : 'Activate',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: AdminTheme.red,
                    ),
                    title: Text(
                      'Delete user',
                      style: TextStyle(fontSize: 13, color: AdminTheme.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static int _id(Map<String, dynamic> row) => (row['id'] as num?)?.toInt() ?? 0;

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

/* =========================================================================
 * add / edit form
 * ========================================================================= */

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.user});

  /// Null for "Add User", a row from the list for "Edit User".
  final Map<String, dynamic>? user;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;

  String _role = 'user';
  bool _isActive = true;
  bool _busy = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user ?? {};
    _name = TextEditingController(text: (user['name'] ?? '').toString());
    _email = TextEditingController(text: (user['email'] ?? '').toString());
    _phone = TextEditingController(text: (user['phone'] ?? '').toString());
    _password = TextEditingController();
    _role = (user['role'] ?? 'user').toString();
    _isActive = user['is_active'] == null
        ? true
        : (user['is_active'] is num
              ? (user['is_active'] as num) != 0
              : user['is_active'].toString() == 'true');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'role': _role,
      'is_active': _isActive,
    };

    // Only send a password when the admin actually typed one - on edit that
    // means "leave the password alone".
    if (_password.text.trim().isNotEmpty) {
      body['password'] = _password.text.trim();
    }

    final id = (widget.user?['id'] as num?)?.toInt();
    final response = _isEdit && id != null
        ? await AdminService.updateUser(id, body)
        : await AdminService.createUser(body);

    if (!mounted) return;

    setState(() => _busy = false);

    if (response['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    adminToast(
      context,
      (response['message'] ?? 'Could not save the user.').toString(),
      error: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: AdminTheme.glow(AdminTheme.primary),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        _isEdit
                            ? Icons.edit_rounded
                            : Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: AdminTheme.violet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEdit ? 'Edit User' : 'Add New User',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  dropdownColor: AdminTheme.surfaceAlt,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.verified_user_outlined, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Fan / User')),
                    DropdownMenuItem(value: 'editor', child: Text('Editor')),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrator'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? 'user'),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'New password (optional)' : 'Password',
                    helperText: _isEdit
                        ? 'Leave blank to keep the current password.'
                        : 'Defaults to Fandom@123 if left blank.',
                    helperStyle: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 11,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                    ),
                  ),
                  validator: (v) {
                    if (_isEdit) return null;
                    if (v != null && v.isNotEmpty && v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AdminTheme.green,
                  title: Text(
                    'Account active',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    'Inactive users cannot sign in to the app.',
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.textSecondary,
                          side: BorderSide(color: AdminTheme.border),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminPrimaryButton(
                        label: _isEdit ? 'Save Changes' : 'Create User',
                        icon: Icons.save_rounded,
                        loading: _busy,
                        expand: true,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
