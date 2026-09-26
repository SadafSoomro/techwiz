import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Notifications (broadcast announcements to the fan base).
class AdminNotificationsSection extends StatefulWidget {
  const AdminNotificationsSection({super.key});

  @override
  State<AdminNotificationsSection> createState() =>
      _AdminNotificationsSectionState();
}

class _AdminNotificationsSectionState extends State<AdminNotificationsSection> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic> _stats = {};

  String _audience = 'all';
  String _icon = 'campaign';
  bool _sending = false;
  bool _loading = true;
  String? _error;

  static const _audiences = {
    'all': 'All Users',
    'new': 'New Users (7 days)',
    'active': 'Active Fans',
    'admins': 'Administrators',
  };

  static const _icons = {
    'campaign': Icons.campaign_rounded,
    'new_releases': Icons.new_releases_rounded,
    'event': Icons.event_rounded,
    'local_offer': Icons.local_offer_rounded,
    'system_update': Icons.system_update_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AdminService.notifications();

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _notifications = (response['notifications'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _stats = Map<String, dynamic>.from(response['stats'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load notifications.')
            .toString();
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await adminConfirm(
      context,
      title: 'Send notification?',
      message: 'This will be delivered to "${_audiences[_audience]}".',
      confirmLabel: 'Send',
    );
    if (!confirmed || !mounted) return;

    setState(() => _sending = true);

    final response = await AdminService.sendNotification({
      'title': _titleController.text.trim(),
      'message': _messageController.text.trim(),
      'audience': _audience,
      'icon': _icon,
    });

    if (!mounted) return;
    setState(() => _sending = false);

    if (response['success'] == true) {
      _titleController.clear();
      _messageController.clear();
      adminToast(context, (response['message'] ?? 'Sent').toString());
      _load();
    } else {
      adminToast(
        context,
        (response['message'] ?? 'Could not send the notification.').toString(),
        error: true,
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await adminConfirm(
      context,
      title: 'Remove from history?',
      message:
          'This only clears the admin record - notifications already '
          'delivered to users stay in their bell.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.deleteNotification(
      (item['id'] as num).toInt(),
    );
    if (!mounted) return;

    adminToast(
      context,
      (response['message'] ?? 'Removed').toString(),
      error: response['success'] != true,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 940;

        final composer = _buildComposer();
        final history = _buildHistory();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                title: 'Notifications',
                subtitle:
                    'Broadcast announcements to the Fandom Verse community',
                icon: Icons.campaign_rounded,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AdminPill(
                    label: '${_num(_stats['total'])} broadcasts',
                    color: AdminTheme.indigo,
                    icon: Icons.send_rounded,
                  ),
                  AdminPill(
                    label: '${_num(_stats['reach'])} total reach',
                    color: AdminTheme.green,
                    icon: Icons.groups_rounded,
                  ),
                  AdminPill(
                    label:
                        '${_num(_stats['inAppUserNotifications'])} in-app rows',
                    color: AdminTheme.cyan,
                    icon: Icons.notifications_active_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (stacked) ...[
                composer,
                const SizedBox(height: 18),
                history,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 420, child: composer),
                    const SizedBox(width: 18),
                    Expanded(child: history),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return AdminPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_notifications_rounded,
                  size: 17,
                  color: AdminTheme.violet,
                ),
                const SizedBox(width: 9),
                Text(
                  'Compose Broadcast',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: AdminTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              style: TextStyle(color: AdminTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Message is required'
                  : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              dropdownColor: AdminTheme.surfaceAlt,
              style: TextStyle(color: AdminTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Audience',
                prefixIcon: Icon(Icons.group_outlined, size: 18),
              ),
              items: _audiences.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _audience = value ?? 'all'),
            ),
            const SizedBox(height: 16),
            Text(
              'Icon',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: _icons.entries.map((entry) {
                final selected = entry.key == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = entry.key),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? AdminTheme.primary.withValues(alpha: 0.2)
                          : AdminTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selected
                            ? AdminTheme.primary
                            : AdminTheme.border,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 18,
                      color: selected
                          ? AdminTheme.violet
                          : AdminTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            AdminPrimaryButton(
              label: 'Send Notification',
              icon: Icons.send_rounded,
              loading: _sending,
              expand: true,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 17,
                color: AdminTheme.cyan,
              ),
              const SizedBox(width: 9),
              Text(
                'Sent History',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const AdminLoader(label: 'Loading history...')
          else if (_error != null)
            AdminErrorState(message: _error!, onRetry: _load)
          else if (_notifications.isEmpty)
            const AdminEmptyState(
              message: 'No notifications sent yet.',
              icon: Icons.notifications_off_rounded,
            )
          else
            ..._notifications.map(
              (item) => AdminListRow(
                title: (item['title'] ?? '').toString(),
                subtitle:
                    '${(item['message'] ?? '')}\n'
                    'to ${_audiences[item['audience']] ?? item['audience']} '
                    '- ${AdminTheme.compact(_num(item['sent_count']))} recipients',
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AdminTheme.indigo.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _icons[(item['icon'] ?? 'campaign').toString()] ??
                        Icons.campaign_rounded,
                    size: 17,
                    color: AdminTheme.indigo,
                  ),
                ),
                trailing: Text(
                  (item['ago'] ?? '').toString(),
                  style: TextStyle(
                    color: AdminTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                menu: IconButton(
                  tooltip: 'Remove from history',
                  onPressed: () => _delete(item),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AdminTheme.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    if (value == null) return 0;
    return num.tryParse(value.toString()) ?? 0;
  }
}
