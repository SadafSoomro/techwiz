import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Logs & Analytics.
///
/// User activity / system logs / error logs / API performance, all read from
/// the admin_logs stream plus live process metrics from the server.
class AdminLogsSection extends StatefulWidget {
  const AdminLogsSection({super.key});

  @override
  State<AdminLogsSection> createState() => _AdminLogsSectionState();
}

class _AdminLogsSectionState extends State<AdminLogsSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _apiPerformance = [];
  List<Map<String, dynamic>> _dailyActivity = [];
  Map<String, dynamic> _counts = {};
  Map<String, dynamic> _system = {};
  Map<String, dynamic> _pagination = {};

  String _level = '';
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

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AdminService.logs(
      level: _level,
      search: _searchController.text.trim(),
      page: page,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _logs = (response['logs'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _apiPerformance = (response['apiPerformance'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _dailyActivity = (response['dailyActivity'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _counts = Map<String, dynamic>.from(response['counts'] ?? {});
        _system = Map<String, dynamic>.from(response['system'] ?? {});
        _pagination = Map<String, dynamic>.from(response['pagination'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load the logs.').toString();
        _loading = false;
      });
    }
  }

  int get _page => (_pagination['page'] as num?)?.toInt() ?? 1;
  int get _pages => (_pagination['pages'] as num?)?.toInt() ?? 1;
  int get _total => (_pagination['total'] as num?)?.toInt() ?? 0;

  Future<void> _clear({String level = ''}) async {
    final confirmed = await adminConfirm(
      context,
      title: level.isEmpty ? 'Clear all logs?' : 'Clear $level logs?',
      message:
          'Audit history will be permanently removed. '
          'The clear action itself is still recorded.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.clearLogs(level: level);
    if (!mounted) return;

    adminToast(
      context,
      (response['message'] ?? 'Logs cleared.').toString(),
      error: response['success'] != true,
    );
    _load(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Logs & Analytics',
            subtitle:
                '${AdminTheme.compact(_num(_counts['all']))} recorded events',
            icon: Icons.insights_rounded,
            action: OutlinedButton.icon(
              onPressed: () => _clear(),
              icon: const Icon(Icons.delete_sweep_rounded, size: 17),
              label: const Text('Clear Logs'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.red,
                side: BorderSide(color: AdminTheme.red.withValues(alpha: 0.5)),
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildOverview(),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 980;

                if (stacked) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildLogStream(expanded: false),
                        const SizedBox(height: 18),
                        _buildAnalytics(),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildLogStream(expanded: true)),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: _buildAnalytics()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return AdminStatGrid(
      cards: [
        AdminStatCard(
          label: 'Total Events',
          value: AdminTheme.compact(_num(_counts['all'])),
          icon: Icons.receipt_long_rounded,
          color: AdminTheme.indigo,
        ),
        AdminStatCard(
          label: 'Info',
          value: AdminTheme.compact(_num(_counts['info'])),
          icon: Icons.info_outline_rounded,
          color: AdminTheme.cyan,
        ),
        AdminStatCard(
          label: 'Warnings',
          value: AdminTheme.compact(_num(_counts['warn'])),
          icon: Icons.warning_amber_rounded,
          color: AdminTheme.amber,
        ),
        AdminStatCard(
          label: 'Errors',
          value: AdminTheme.compact(_num(_counts['error'])),
          icon: Icons.error_outline_rounded,
          color: AdminTheme.red,
          caption: 'Server uptime ${_uptime()}',
        ),
      ],
    );
  }

  Widget _buildLogStream({required bool expanded}) {
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSearchField(
          controller: _searchController,
          hint: 'Search logs by action or detail...',
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), _load);
          },
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 12),
        AdminFilterChips(
          options: const {
            '': 'All levels',
            'info': 'Info',
            'warn': 'Warning',
            'error': 'Error',
          },
          selected: _level,
          onSelected: (value) {
            setState(() => _level = value);
            _load();
          },
        ),
        const SizedBox(height: 14),
        Expanded(child: _buildLogRows()),
        if (!_loading && _error == null)
          AdminPager(
            page: _page,
            pages: _pages,
            total: _total,
            onPage: (page) => _load(page: page),
          ),
      ],
    );

    if (!expanded) {
      return SizedBox(height: 520, child: list);
    }
    return list;
  }

  Widget _buildLogRows() {
    if (_loading) return const AdminLoader(label: 'Loading logs...');
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }
    if (_logs.isEmpty) {
      return const AdminEmptyState(
        message: 'No log entries match these filters.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return AdminPanel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _logs.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AdminTheme.border,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final log = _logs[index];
          final level = (log['level'] ?? 'info').toString();
          final color = AdminTheme.forLevel(level);

          return AdminListRow(
            title: (log['action'] ?? '')
                .toString()
                .replaceAll('_', ' ')
                .toUpperCase(),
            subtitle: [
              if ((log['details'] ?? '').toString().isNotEmpty)
                (log['details'] ?? '').toString(),
              if ((log['admin_email'] ?? '').toString().isNotEmpty)
                'by ${log['admin_email']}',
              if ((log['target_type'] ?? '').toString().isNotEmpty)
                'target: ${log['target_type']}#${log['target_id'] ?? '-'}',
            ].join('  -  '),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                level.toLowerCase() == 'error'
                    ? Icons.error_outline_rounded
                    : level.toLowerCase() == 'warn'
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                size: 15,
                color: color,
              ),
            ),
            pills: [
              AdminPill(label: level, color: color),
              if ((log['admin_email'] ?? '').toString().isEmpty)
                AdminPill(
                  label: 'system',
                  color: AdminTheme.textSecondary,
                ),
            ],
            trailing: Text(
              (log['ago'] ?? '').toString(),
              style: TextStyle(color: AdminTheme.textMuted, fontSize: 11),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalytics() {
    final maxApi = _apiPerformance.fold<num>(
      0,
      (max, a) => _num(a['hits']) > max ? _num(a['hits']) : max,
    );
    final maxDay = _dailyActivity.fold<num>(
      0,
      (max, d) => _num(d['total']) > max ? _num(d['total']) : max,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Performance',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Most frequent admin actions',
                  style: TextStyle(color: AdminTheme.textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                if (_apiPerformance.isEmpty)
                  Text(
                    'No activity recorded.',
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 12.5,
                    ),
                  )
                else
                  ..._apiPerformance.map(
                    (a) => AdminBarRow(
                      label: (a['action'] ?? '').toString().replaceAll(
                        '_',
                        ' ',
                      ),
                      value: _num(a['hits']),
                      maxValue: maxApi,
                      color: AdminTheme.indigo,
                      trailingText:
                          '${AdminTheme.compact(_num(a['hits']))} hits',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Activity',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Log entries per day',
                  style: TextStyle(color: AdminTheme.textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                if (_dailyActivity.isEmpty)
                  Text(
                    'No activity recorded.',
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 12.5,
                    ),
                  )
                else
                  ..._dailyActivity.map(
                    (d) => AdminBarRow(
                      label: (d['day'] ?? '').toString(),
                      value: _num(d['total']),
                      maxValue: maxDay,
                      color: AdminTheme.green,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildSystemCard(),
        ],
      ),
    );
  }

  Widget _buildSystemCard() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory_rounded,
                size: 17,
                color: AdminTheme.violet,
              ),
              const SizedBox(width: 9),
              Text(
                'System',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              AdminMiniStat(
                label: 'Node',
                value: (_system['nodeVersion'] ?? '-').toString(),
              ),
              AdminMiniStat(
                label: 'memory',
                value: '${_num(_system['memoryMb'])} MB',
                color: AdminTheme.cyan,
              ),
              AdminMiniStat(
                label: 'uptime',
                value: _uptime(),
                color: AdminTheme.green,
              ),
              AdminMiniStat(
                label: 'platform',
                value: (_system['platforms'] ?? _system['platform'] ?? '-')
                    .toString(),
                color: AdminTheme.amber,
              ),
              AdminMiniStat(
                label: 'environment',
                value: (_system['environment'] ?? '-').toString(),
                color: AdminTheme.pink,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _clear(level: 'warn'),
                  icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                  label: const Text('Clear warnings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.amber,
                    side: BorderSide(
                      color: AdminTheme.amber.withValues(alpha: 0.5),
                    ),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _uptime() {
    final seconds = _num(_system['uptimeSeconds']).toInt();
    if (seconds <= 0) return '-';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).floor()}m';
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    return '${hours}h ${minutes}m';
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    if (value == null) return 0;
    return num.tryParse(value.toString()) ?? 0;
  }
}
