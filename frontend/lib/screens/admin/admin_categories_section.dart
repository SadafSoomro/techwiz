import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Manage Categories.
///
/// The platform keeps three separate category tables (shop, fandom interests
/// and event types). Rather than three near-identical screens, the kind
/// selector at the top switches which table the panel is editing.
class AdminCategoriesSection extends StatefulWidget {
  const AdminCategoriesSection({super.key});

  @override
  State<AdminCategoriesSection> createState() => _AdminCategoriesSectionState();
}

class _AdminCategoriesSectionState extends State<AdminCategoriesSection> {
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic> _counts = {};

  String _kind = 'product';
  bool _loading = true;
  String? _error;

  static const _kindLabels = {
    'product': 'Shop Categories',
    'fandom': 'Fandom Interests',
    'event': 'Event Categories',
  };

  static const _kindHints = {
    'product':
        'Groups the merchandise catalogue (Figures, Apparel, Digital...).',
    'fandom': 'The interests fans pick at sign-up - drives their home feed.',
    'event': 'Event types used by the calendar and map filters.',
  };

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

    final response = await AdminService.categories(kind: _kind);

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _categories = (response['categories'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _counts = Map<String, dynamic>.from(response['counts'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load categories.')
            .toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? category}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CategoryFormDialog(kind: _kind, category: category),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> category) async {
    final used = _num(category['usage_count']);
    if (used > 0) {
      adminToast(
        context,
        'Cannot delete "${category['name']}" - $used item(s) still use it.',
        error: true,
      );
      return;
    }

    final confirmed = await adminConfirm(
      context,
      title: 'Delete category?',
      message:
          '"${category['name']}" will be removed from the '
          '${_kindLabels[_kind]} list.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.deleteCategory(_id(category), _kind);
    if (!mounted) return;

    adminToast(
      context,
      (response['message'] ?? 'Deleted').toString(),
      error: response['success'] != true,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Manage Categories',
            subtitle:
                '${AdminTheme.compact(_num(_counts['all']))} '
                '${_kindLabels[_kind]!.toLowerCase()} - '
                '${AdminTheme.compact(_num(_counts['used']))} in use',
            icon: Icons.category_rounded,
            action: AdminPrimaryButton(
              label: 'Add Category',
              icon: Icons.add_rounded,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: 18),
          AdminFilterChips(
            options: _kindLabels,
            selected: _kind,
            onSelected: (value) {
              setState(() => _kind = value);
              _load();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AdminTheme.textMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _kindHints[_kind] ?? '',
                  style: TextStyle(
                    color: AdminTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              AdminPill(
                label: '${_num(_counts['all'])} total',
                color: AdminTheme.indigo,
                icon: Icons.list_alt_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['used'])} in use',
                color: AdminTheme.green,
                icon: Icons.check_circle_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['empty'])} unused',
                color: AdminTheme.amber,
                icon: Icons.inbox_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const AdminLoader(label: 'Loading categories...');
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }
    if (_categories.isEmpty) {
      return AdminEmptyState(
        message: 'No ${_kindLabels[_kind]!.toLowerCase()} yet.',
        icon: Icons.category_outlined,
        action: AdminPrimaryButton(
          label: 'Add the first one',
          icon: Icons.add_rounded,
          onPressed: () => _openForm(),
        ),
      );
    }

    return AdminPanel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AdminTheme.border,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final used = _num(category['usage_count']);
          final color = _parseColor((category['color'] ?? '').toString());

          return AdminListRow(
            title: (category['name'] ?? 'Unnamed').toString(),
            subtitle: (category['description'] ?? '').toString().isEmpty
                ? (category['slug'] ?? '').toString()
                : (category['description'] ?? '').toString(),
            onTap: () => _openForm(category: category),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(
                _parseIcon((category['icon'] ?? '').toString()),
                size: 18,
                color: color,
              ),
            ),
            pills: [
              AdminPill(
                label: used > 0
                    ? '$used item${used == 1 ? '' : 's'}'
                    : 'unused',
                color: used > 0 ? AdminTheme.green : AdminTheme.amber,
              ),
              if ((category['hashtag'] ?? '').toString().isNotEmpty)
                AdminPill(
                  label: (category['hashtag'] ?? '').toString(),
                  color: AdminTheme.cyan,
                ),
            ],
            menu: PopupMenuButton<String>(
              color: AdminTheme.surfaceAlt,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AdminTheme.textMuted,
              ),
              onSelected: (value) {
                if (value == 'edit') _openForm(category: category);
                if (value == 'delete') _delete(category);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded, size: 17),
                    title: Text(
                      'Edit category',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: used == 0,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: used == 0 ? AdminTheme.red : AdminTheme.textMuted,
                    ),
                    title: Text(
                      used == 0 ? 'Delete category' : 'In use - cannot delete',
                      style: TextStyle(
                        fontSize: 13,
                        color: used == 0
                            ? AdminTheme.red
                            : AdminTheme.textMuted,
                      ),
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
}

/// The backend stores a hex string; fall back to the brand colour.
Color _parseColor(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return AdminTheme.primary;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return AdminTheme.primary;
  return Color(0xFF000000 | value);
}

/// Maps the stored Material icon name onto an IconData.
IconData _parseIcon(String name) {
  const icons = {
    'category': Icons.category_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'movie': Icons.movie_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    'music_note': Icons.music_note_rounded,
    'checkroom': Icons.checkroom_rounded,
    'diamond': Icons.diamond_rounded,
    'palette': Icons.palette_rounded,
    'photo_camera': Icons.photo_camera_rounded,
    'celebration': Icons.celebration_rounded,
    'groups': Icons.groups_rounded,
    'place': Icons.place_rounded,
  };
  return icons[name] ?? Icons.category_rounded;
}

/* =========================================================================
 * add / edit category
 * ========================================================================= */

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({required this.kind, this.category});

  final String kind;
  final Map<String, dynamic>? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _hashtag;

  String _icon = 'category';
  String _colorHex = '#7C3AED';
  bool _busy = false;

  bool get _isEdit => widget.category != null;

  static const _colorChoices = [
    '#7C3AED',
    '#6366F1',
    '#06B6D4',
    '#10B981',
    '#F59E0B',
    '#EC4899',
    '#EF4444',
  ];

  static const _iconChoices = [
    'category',
    'sports_esports',
    'movie',
    'auto_stories',
    'music_note',
    'checkroom',
    'diamond',
    'palette',
    'photo_camera',
    'celebration',
    'groups',
    'place',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.category ?? {};
    _name = TextEditingController(text: (c['name'] ?? '').toString());
    _description = TextEditingController(
      text: (c['description'] ?? '').toString(),
    );
    _hashtag = TextEditingController(text: (c['hashtag'] ?? '').toString());
    _icon = (c['icon'] ?? 'category').toString();
    _colorHex = (c['color'] ?? '#7C3AED').toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _hashtag.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final body = <String, dynamic>{
      'kind': widget.kind,
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'icon': _icon,
      'color': _colorHex,
      if (widget.kind == 'fandom') 'hashtag': _hashtag.text.trim(),
    };

    final id = (widget.category?['id'] as num?)?.toInt();
    final response = _isEdit && id != null
        ? await AdminService.updateCategory(id, body)
        : await AdminService.createCategory(body);

    if (!mounted) return;
    setState(() => _busy = false);

    if (response['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    adminToast(
      context,
      (response['message'] ?? 'Could not save the category.').toString(),
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
                Text(
                  _isEdit ? 'Edit Category' : 'Add Category',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Category name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Category name is required'
                      : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                if (widget.kind == 'fandom') ...[
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _hashtag,
                    style: TextStyle(color: AdminTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Hashtag',
                      hintText: '#Anime',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Colour',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colorChoices.map((hex) {
                    final selected =
                        hex.toLowerCase() == _colorHex.toLowerCase();
                    return GestureDetector(
                      onTap: () => setState(() => _colorHex = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _parseColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Icon',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: _iconChoices.map((name) {
                    final selected = name == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = name),
                      child: Container(
                        width: 40,
                        height: 40,
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
                          _parseIcon(name),
                          size: 18,
                          color: selected
                              ? AdminTheme.violet
                              : AdminTheme.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
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
                        label: _isEdit ? 'Save Changes' : 'Create',
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
