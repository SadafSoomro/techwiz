import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'admin_backup_section.dart';
import 'admin_categories_section.dart';
import 'admin_content_section.dart';
import 'admin_dashboard_section.dart';
import 'admin_events_section.dart';
import 'admin_logs_section.dart';
import 'admin_login_screen.dart';
import 'admin_notifications_section.dart';
import 'admin_products_section.dart';
import 'admin_security_section.dart';
import 'admin_users_section.dart';

/// One entry in the admin navigation.
class AdminNavItem {
  const AdminNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

const List<AdminNavItem> adminNavItems = [
  AdminNavItem(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.home_rounded,
    builder: _dashboard,
  ),
  AdminNavItem(
    id: 'users',
    label: 'Users',
    icon: Icons.people_alt_rounded,
    builder: _users,
  ),
  AdminNavItem(
    id: 'content',
    label: 'Content',
    icon: Icons.smart_display_rounded,
    builder: _content,
  ),
  AdminNavItem(
    id: 'events',
    label: 'Events',
    icon: Icons.calendar_today_rounded,
    builder: _events,
  ),
  AdminNavItem(
    id: 'logs',
    label: 'Analytics',
    icon: Icons.bar_chart_rounded,
    builder: _logs,
  ),
  AdminNavItem(
    id: 'security',
    label: 'Settings',
    icon: Icons.settings_rounded,
    builder: _security,
  ),
  AdminNavItem(
    id: 'products',
    label: 'Products',
    icon: Icons.storefront_rounded,
    builder: _products,
  ),
  AdminNavItem(
    id: 'categories',
    label: 'Categories',
    icon: Icons.category_rounded,
    builder: _categories,
  ),
  AdminNavItem(
    id: 'notifications',
    label: 'Notifications',
    icon: Icons.campaign_rounded,
    builder: _notifications,
  ),
  AdminNavItem(
    id: 'backup',
    label: 'Backup',
    icon: Icons.storage_rounded,
    builder: _backup,
  ),
];

Widget _dashboard(BuildContext context) => const AdminDashboardSection();
Widget _users(BuildContext context) => const AdminUsersSection();
Widget _content(BuildContext context) => const AdminContentSection();
Widget _events(BuildContext context) => const AdminEventsSection();
Widget _products(BuildContext context) => const AdminProductsSection();
Widget _categories(BuildContext context) => const AdminCategoriesSection();
Widget _notifications(BuildContext context) =>
    const AdminNotificationsSection();
Widget _security(BuildContext context) => const AdminSecuritySection();
Widget _backup(BuildContext context) => const AdminBackupSection();
Widget _logs(BuildContext context) => const AdminLogsSection();

/// Allows children anywhere in the admin panel to jump between sections.
class AdminNavScope extends InheritedWidget {
  const AdminNavScope({
    super.key,
    required this.currentSection,
    required this.goTo,
    required super.child,
  });

  final String currentSection;
  final ValueChanged<String> goTo;

  static AdminNavScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminNavScope>();

  static AdminNavScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AdminNavScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AdminNavScope oldWidget) =>
      currentSection != oldWidget.currentSection;
}

/// The admin panel frame: sidebar on desktop, drawer on mobile.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _section = 'dashboard';
  int? _refreshIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // The panel is normally opened straight from the unified login screen, so
    // AuthProvider has only just mirrored the token into AdminStorage. Adopt
    // it here, otherwise the header keeps showing the "Administrator"
    // fallback name instead of the signed-in admin's real identity.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AdminProvider>();
      if (!provider.signedIn) provider.restoreSession();
    });
  }

  AdminNavItem get _current =>
      adminNavItems.firstWhere((item) => item.id == _section);

  void _go(String id) {
    setState(() => _section = id);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _refreshCurrent() {
    setState(() => _refreshIndex = (_refreshIndex ?? 0) + 1);
  }

  void _openEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => const _EditProfileDialog(),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await adminConfirm(
      context,
      title: 'Sign out of Admin Portal?',
      message: 'You will need your admin credentials to sign back in.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await context.read<AdminProvider>().signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return AdminNavScope(
      currentSection: _section,
      goTo: _go,
      child: AdminThemeScope(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 980;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: AdminTheme.bg,
              drawer: isDesktop
                  ? null
                  : Drawer(
                      backgroundColor: AdminTheme.sidebar,
                      child: _buildSidebar(compact: true),
                    ),
              body: Row(
                children: [
                  if (isDesktop) _buildSidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(isDesktop: isDesktop),
                        Expanded(
                          child: KeyedSubtree(
                            key: ValueKey('$_section-${_refreshIndex ?? 0}'),
                            child: _current.builder(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isDesktop}) {
    final isLight = AdminTheme.isLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isMobile = w < 600;

        return Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 18),
          decoration: BoxDecoration(
            color: AdminTheme.bgElevated,
            border: Border(
              bottom: BorderSide(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.menu_rounded),
                  color: AdminTheme.textPrimary,
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                SizedBox(width: isMobile ? 4 : 8),
              ],
              // Search pill: flexible on mobile, fixed on desktop
              Expanded(
                flex: isDesktop ? 0 : 1,
                child: Container(
                  width: isDesktop ? 340 : null,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF13182B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.12)
                          : const Color(0xFF232A42),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: AdminTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: isMobile ? 'Search...' : 'Search users, content, events...',
                            hintStyle: TextStyle(
                              color: AdminTheme.textMuted,
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            color: AdminTheme.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDesktop) const Spacer(),
              if (!isDesktop) const SizedBox(width: 4),
              // Notification bell with pink dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications_none_rounded, size: 19),
                    color: AdminTheme.textSecondary,
                    onPressed: () => _go('notifications'),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEC4899),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              // Refresh live data (on tablet/desktop)
              if (!isMobile)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: 'Refresh live data',
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  color: AdminTheme.textSecondary,
                  onPressed: _refreshCurrent,
                ),
              // Theme switch
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                tooltip: isLight ? 'Switch to dark mode' : 'Switch to light mode',
                icon: Icon(
                  isLight ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                  size: 18,
                ),
                color: AdminTheme.textSecondary,
                onPressed: () => context.read<AdminProvider>().toggleTheme(),
              ),
              SizedBox(width: isMobile ? 4 : 8),
              // User profile menu
              _buildAdminMenu(isMobile: isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminMenu({bool isMobile = false}) {
    final provider = context.watch<AdminProvider>();
    final isLight = AdminTheme.isLight;
    final name = provider.adminName.isNotEmpty ? provider.adminName : 'Shazmeen';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      color: AdminTheme.surfaceAlt,
      offset: const Offset(0, 44),
      onSelected: (value) {
        if (value == 'edit_profile') _openEditProfileDialog();
        if (value == 'logout') _confirmLogout();
        if (value == 'security') _go('security');
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.adminName,
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                provider.adminEmail,
                style: TextStyle(
                  color: AdminTheme.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'edit_profile',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AdminTheme.textSecondary,
            ),
            title: const Text('Edit profile', style: TextStyle(fontSize: 13.5)),
          ),
        ),
        PopupMenuItem(
          value: 'security',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.security_rounded,
              size: 18,
              color: AdminTheme.textSecondary,
            ),
            title: const Text('Security settings', style: TextStyle(fontSize: 13.5)),
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.logout_rounded,
              size: 18,
              color: AdminTheme.red,
            ),
            title: Text(
              'Sign out',
              style: TextStyle(fontSize: 13.5, color: AdminTheme.red),
            ),
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF13182B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLight
                ? Colors.black.withValues(alpha: 0.12)
                : const Color(0xFF232A42),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7047EB), Color(0xFF9333EA)],
                ),
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AdminTheme.textMuted,
                size: 15,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({bool compact = false}) {
    final isLight = AdminTheme.isLight;
    final primaryItems = adminNavItems.take(6).toList();
    final secondaryItems = adminNavItems.skip(6).toList();

    return Container(
      width: compact ? null : 230,
      decoration: BoxDecoration(
        color: AdminTheme.sidebar,
        border: Border(
          right: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top brand
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'FandomVerse',
                    style: GoogleFonts.outfit(
                      color: AdminTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Navigation list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...primaryItems.map((item) => _buildNavTile(item)),
                  if (secondaryItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        'MORE TOOLS',
                        style: TextStyle(
                          color: AdminTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    ...secondaryItems.map((item) => _buildNavTile(item)),
                  ],
                ],
              ),
            ),
            // Bottom community footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFFEC4899),
                    size: 18,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Building a\nbetter community\n— together',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SidebarWavePainter(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(AdminNavItem item) {
    final selected = item.id == _section;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _go(item.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF7047EB) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: selected ? Colors.white : AdminTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : AdminTheme.textSecondary,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7047EB), Color(0xFFEC4899)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.95,
      size.width * 0.6,
      size.height * 0.35,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      0,
      size.width,
      size.height * 0.45,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog();

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscure = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminProvider>();
    _nameController = TextEditingController(text: provider.adminName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AdminProvider>();
    final newName = _nameController.text.trim();
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    final nameChanged = newName != provider.adminName;
    final passwordChanging = newPassword.isNotEmpty;

    if (!nameChanged && !passwordChanging) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);

    try {
      final response = await AdminService.updateProfile(
        name: nameChanged ? newName : null,
        currentPassword: passwordChanging ? currentPassword : null,
        newPassword: passwordChanging ? newPassword : null,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        if (response['admin'] != null) {
          await provider.updateAdminData(
            Map<String, dynamic>.from(response['admin']),
          );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        adminToast(context, 'Profile updated successfully.');
      } else {
        setState(() {
          _saving = false;
          _errorMessage =
              (response['message'] ?? 'Failed to update profile.').toString();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: provider.lightMode ? Colors.black : Colors.white,
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: provider.lightMode ? Colors.black : Colors.white,
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        Icons.manage_accounts_rounded,
                        color: AdminTheme.violet,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update your administrator name or password',
                            style: TextStyle(
                              color: AdminTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AdminTheme.textMuted,
                        size: 20,
                      ),
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AdminTheme.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AdminTheme.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AdminTheme.red,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AdminTheme.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Email (Gmail) - strictly read only
                Text(
                  'Email Address (Cannot be changed)',
                  style: TextStyle(
                    color: AdminTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: provider.adminEmail,
                  readOnly: true,
                  enabled: false,
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                    suffixIcon: Tooltip(
                      message: 'Email address cannot be changed',
                      child: Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: AdminTheme.textMuted,
                      ),
                    ),
                    filled: true,
                    fillColor: AdminTheme.surfaceAlt.withValues(alpha: 0.5),
                    helperText: 'Gmail address cannot be altered',
                    helperStyle: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Name - Editable
                Text(
                  'Full Name',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Admin Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password change section
                Row(
                  children: [
                    Expanded(child: Divider(color: AdminTheme.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Change Password (Optional)',
                        style: TextStyle(
                          color: AdminTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AdminTheme.border)),
                  ],
                ),
                const SizedBox(height: 14),

                // Current password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscure,
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 18),
                    helperText: 'Required only if changing password',
                    helperStyle: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  validator: (v) {
                    if (_newPasswordController.text.isNotEmpty &&
                        (v == null || v.isEmpty)) {
                      return 'Current password is required to set a new password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // New password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscure,
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon:
                        const Icon(Icons.lock_reset_rounded, size: 18),
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
                    if (v != null && v.isNotEmpty && v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Confirm new password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscure,
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon:
                        Icon(Icons.check_circle_outline_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (_newPasswordController.text.isNotEmpty) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (v != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AdminTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AdminPrimaryButton(
                      label: 'Save Changes',
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: _handleSave,
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
