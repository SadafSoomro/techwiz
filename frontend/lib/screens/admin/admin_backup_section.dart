import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Backup & Database.
///
/// The SQLite file IS the database, so a backup is a real file copy on the
/// server. This screen reports the live table sizes and lets an admin take and
/// then download a copy.
class AdminBackupSection extends StatefulWidget {
  const AdminBackupSection({super.key});

  @override
  State<AdminBackupSection> createState() => _AdminBackupSectionState();
}

class _AdminBackupSectionState extends State<AdminBackupSection> {
  Map<String, dynamic> _database = {};
  List<Map<String, dynamic>> _tables = [];
  List<Map<String, dynamic>> _backups = [];

  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AdminService.backupInfo();

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _database = Map<String, dynamic>.from(response['database'] ?? {});
        _tables = (response['tables'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _backups = (response['backups'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not read the backup info.')
            .toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);

    final response = await AdminService.createBackup();

    if (!mounted) return;
    setState(() => _creating = false);

    if (response['success'] == true) {
      adminToast(
        context,
        (response['message'] ?? 'Backup created.').toString(),
      );
      _load();
    } else {
      adminToast(
        context,
        (response['message'] ?? 'Could not create the backup.').toString(),
        error: true,
      );
    }
  }

  /// The API streams the file, so we hand the admin a tokenised link to copy
  /// into a browser rather than pulling the whole .sqlite into memory.
  Future<void> _downloadUrl({String? file}) async {
    final url = await AdminService.backupDownloadUrl(file: file);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Download Backup',
          style: TextStyle(
            color: AdminTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste this link into a browser to download the file. It carries '
                'your admin token, so treat it as a secret.',
                style: TextStyle(
                  color: AdminTheme.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: SelectableText(
                  url,
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
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
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              adminToast(context, 'Download link copied to clipboard.');
            },
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('Copy link'),
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AdminLoader(label: 'Reading database...');
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Backup & Database',
            subtitle: 'SQLite storage - backup and restore points',
            icon: Icons.storage_rounded,
            action: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _downloadUrl(),
                  icon: const Icon(Icons.download_rounded, size: 17),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.textPrimary,
                    side: BorderSide(color: AdminTheme.border),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AdminPrimaryButton(
                  label: 'Backup Now',
                  icon: Icons.backup_rounded,
                  loading: _creating,
                  onPressed: _create,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AdminStatGrid(
            cards: [
              AdminStatCard(
                label: 'Database File',
                value: (_database['file'] ?? 'mydb.sqlite').toString(),
                icon: Icons.description_rounded,
                color: AdminTheme.indigo,
                caption: '${_prettySize(_num(_database['size']))} on disk',
              ),
              AdminStatCard(
                label: 'Tables',
                value: AdminTheme.compact(_num(_database['tables'])),
                icon: Icons.table_chart_rounded,
                color: AdminTheme.cyan,
              ),
              AdminStatCard(
                label: 'Total Rows',
                value: AdminTheme.compact(_num(_database['totalRows'])),
                icon: Icons.dataset_rounded,
                color: AdminTheme.green,
              ),
              AdminStatCard(
                label: 'Saved Backups',
                value: '${_backups.length}',
                icon: Icons.inventory_rounded,
                color: AdminTheme.amber,
                caption: _backups.isEmpty
                    ? 'No backup taken yet'
                    : 'Latest: ${(_backups.first['file'] ?? '').toString()}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildLastBackupBanner(),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;

              if (stacked) {
                return Column(
                  children: [
                    _buildTableSizes(),
                    const SizedBox(height: 18),
                    _buildBackupList(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTableSizes()),
                  const SizedBox(width: 18),
                  SizedBox(width: 420, child: _buildBackupList()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLastBackupBanner() {
    final hasBackup = _backups.isNotEmpty;
    final last = hasBackup ? _backups.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (hasBackup ? AdminTheme.green : AdminTheme.amber).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (hasBackup ? AdminTheme.green : AdminTheme.amber).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasBackup ? Icons.verified_rounded : Icons.warning_amber_rounded,
            size: 20,
            color: hasBackup ? AdminTheme.green : AdminTheme.amber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasBackup ? 'Last Backup' : 'No backup taken yet',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasBackup
                      ? '${last!['file']}  -  ${_prettySize(_num(last['size']))}  -  '
                            '${_prettyDate((last['created_at'] ?? '').toString())}'
                      : 'Create a backup before making large content changes.',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Database modified\n${_prettyDate((_database['modified'] ?? '').toString())}',
            textAlign: TextAlign.right,
            style: TextStyle(color: AdminTheme.textMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSizes() {
    final maxRows = _tables.fold<num>(
      0,
      (max, t) => _num(t['rows']) > max ? _num(t['rows']) : max,
    );

    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.table_chart_rounded,
                size: 17,
                color: AdminTheme.cyan,
              ),
              const SizedBox(width: 9),
              Text(
                'Table Sizes',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_tables.length} tables',
                style: TextStyle(
                  color: AdminTheme.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_tables.isEmpty)
            Text(
              'No tables found.',
              style: TextStyle(color: AdminTheme.textMuted, fontSize: 12.5),
            )
          else
            ..._tables
                .take(16)
                .map(
                  (t) => AdminBarRow(
                    label: (t['table'] ?? '').toString(),
                    value: _num(t['rows']),
                    maxValue: maxRows,
                    color: _num(t['rows']) == 0
                        ? AdminTheme.textMuted
                        : AdminTheme.cyan,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBackupList() {
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
                'Backup History',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_backups.isEmpty)
            const AdminEmptyState(
              message:
                  'No backups yet. Press "Backup Now" to create the first one.',
              icon: Icons.backup_outlined,
            )
          else
            ..._backups.map(
              (backup) => AdminListRow(
                title: (backup['file'] ?? '').toString(),
                subtitle:
                    '${_prettySize(_num(backup['size']))}  -  '
                    '${_prettyDate((backup['created_at'] ?? '').toString())}',
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AdminTheme.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.save_rounded,
                    size: 17,
                    color: AdminTheme.amber,
                  ),
                ),
                menu: IconButton(
                  tooltip: 'Get download link',
                  onPressed: () =>
                      _downloadUrl(file: (backup['file'] ?? '').toString()),
                  icon: Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: AdminTheme.textSecondary,
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

  static String _prettySize(num bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  static String _prettyDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '-';
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
