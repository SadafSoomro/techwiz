import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Manage Content (news / gallery / video / podcast / deep dive).
class AdminContentSection extends StatefulWidget {
  const AdminContentSection({super.key});

  @override
  State<AdminContentSection> createState() => _AdminContentSectionState();
}

class _AdminContentSectionState extends State<AdminContentSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _counts = {};
  Map<String, dynamic> _pagination = {};

  String _type = '';
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

    final response = await AdminService.content(
      search: _searchController.text.trim(),
      type: _type,
      page: page,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _items = (response['items'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _counts = Map<String, dynamic>.from(response['counts'] ?? {});
        _pagination = Map<String, dynamic>.from(response['pagination'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load content.').toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ContentFormDialog(item: item),
    );
    if (saved == true) _load(page: _page);
  }

  int get _page => (_pagination['page'] as num?)?.toInt() ?? 1;
  int get _pages => (_pagination['pages'] as num?)?.toInt() ?? 1;
  int get _total => (_pagination['total'] as num?)?.toInt() ?? 0;

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await adminConfirm(
      context,
      title: 'Delete content?',
      message:
          '"${item['title']}" will be removed from the app. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.deleteContent(_id(item));
    if (!mounted) return;

    adminToast(
      context,
      (response['message'] ?? 'Deleted').toString(),
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
            title: 'Manage Content',
            subtitle:
                '${AdminTheme.compact(_total)} matching items across '
                '${AdminTheme.compact(_num(_counts['all']))} published pieces',
            icon: Icons.article_rounded,
            action: AdminPrimaryButton(
              label: 'Add Content',
              icon: Icons.add_rounded,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminPill(
                label: '${_num(_counts['all'])} all',
                color: AdminTheme.indigo,
                icon: Icons.library_books_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['news'])} news',
                color: AdminTheme.cyan,
                icon: Icons.newspaper_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['gallery'])} gallery',
                color: AdminTheme.pink,
                icon: Icons.photo_library_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['video'])} video',
                color: AdminTheme.amber,
                icon: Icons.play_circle_fill_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['podcast'])} podcast',
                color: AdminTheme.green,
                icon: Icons.podcasts_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSearchField(
            controller: _searchController,
            hint: 'Search content by title, fandom or author...',
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: 12),
          AdminFilterChips(
            options: const {
              '': 'All types',
              'news': 'News',
              'gallery': 'Gallery',
              'video': 'Video',
              'podcast': 'Podcast',
              'deep_dive': 'Deep Dive',
            },
            selected: _type,
            onSelected: (value) {
              setState(() => _type = value);
              _load();
            },
          ),
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

  Widget _buildList() {
    if (_loading) return const AdminLoader(label: 'Loading content...');
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return const AdminEmptyState(
        message: 'No content matches these filters.',
        icon: Icons.article_outlined,
      );
    }

    return AdminPanel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _items.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AdminTheme.border,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          final published = _toBool(item['is_published']);

          return AdminListRow(
            title: (item['title'] ?? 'Untitled').toString(),
            subtitle:
                '${(item['fandom'] ?? '-')}  -  '
                '${(item['author'] ?? 'unknown author')}  -  '
                '${AdminTheme.compact(_num(item['views_count']))} views',
            onTap: () => _openForm(item: item),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AdminTheme.cyan.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _typeIcon((item['content_type'] ?? '').toString()),
                size: 18,
                color: AdminTheme.cyan,
              ),
            ),
            pills: [
              AdminPill(
                label: (item['content_type'] ?? '').toString().replaceAll(
                  '_',
                  ' ',
                ),
                color: AdminTheme.indigo,
              ),
              AdminPill(
                label: published ? 'published' : 'draft',
                color: published ? AdminTheme.green : AdminTheme.amber,
              ),
              if (_toBool(item['is_featured']))
                AdminPill(
                  label: 'featured',
                  color: AdminTheme.pink,
                  icon: Icons.star_rounded,
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
                if (value == 'edit') _openForm(item: item);
                if (value == 'delete') _delete(item);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded, size: 17),
                    title: Text('Edit content', style: TextStyle(fontSize: 13)),
                  ),
                ),
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
                      'Delete content',
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

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'gallery':
        return Icons.photo_library_rounded;
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'podcast':
        return Icons.podcasts_rounded;
      case 'deep_dive':
        return Icons.psychology_rounded;
      default:
        return Icons.newspaper_rounded;
    }
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
 * add / edit content
 * ========================================================================= */

class _ContentFormDialog extends StatefulWidget {
  const _ContentFormDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_ContentFormDialog> createState() => _ContentFormDialogState();
}

class _ContentFormDialogState extends State<_ContentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _fandom;
  late final TextEditingController _author;
  late final TextEditingController _imageUrl;
  late final TextEditingController _body;

  String _type = 'news';
  bool _published = true;
  bool _featured = false;
  bool _busy = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? {};
    _title = TextEditingController(text: (item['title'] ?? '').toString());
    _subtitle = TextEditingController(
      text: (item['subtitle'] ?? '').toString(),
    );
    _fandom = TextEditingController(
      text: (item['fandom'] ?? 'Anime').toString(),
    );
    _author = TextEditingController(text: (item['author'] ?? '').toString());
    _imageUrl = TextEditingController(
      text: (item['image_url'] ?? '').toString(),
    );
    _body = TextEditingController();
    _type = (item['content_type'] ?? 'news').toString();
    _published = item['is_published'] == null || _toBool(item['is_published']);
    _featured = _toBool(item['is_featured']);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _fandom.dispose();
    _author.dispose();
    _imageUrl.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim(),
      'fandom': _fandom.text.trim(),
      'author': _author.text.trim(),
      'image_url': _imageUrl.text.trim(),
      'content_type': _type,
      'is_published': _published,
      'is_featured': _featured,
      if (_body.text.trim().isNotEmpty) 'body': _body.text.trim(),
    };

    final id = (widget.item?['id'] as num?)?.toInt();
    final response = _isEdit && id != null
        ? await AdminService.updateContent(id, body)
        : await AdminService.createContent(body);

    if (!mounted) return;
    setState(() => _busy = false);

    if (response['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    adminToast(
      context,
      (response['message'] ?? 'Could not save the content.').toString(),
      error: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit Content' : 'Add New Content',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _title,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _subtitle,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Subtitle'),
                ),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  dropdownColor: AdminTheme.surfaceAlt,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Content type'),
                  items: const [
                    DropdownMenuItem(value: 'news', child: Text('News')),
                    DropdownMenuItem(value: 'gallery', child: Text('Gallery')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'podcast', child: Text('Podcast')),
                    DropdownMenuItem(
                      value: 'deep_dive',
                      child: Text('Deep Dive'),
                    ),
                    DropdownMenuItem(value: 'trivia', child: Text('Trivia')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? 'news'),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fandom,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Fandom'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _author,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Author'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _imageUrl,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    prefixIcon: Icon(Icons.image_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _body,
                  maxLines: 3,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: _isEdit
                        ? 'Summary / body (blank keeps the current text)'
                        : 'Summary / body',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _published,
                  onChanged: (value) => setState(() => _published = value),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AdminTheme.green,
                  title: Text(
                    'Published',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    'Drafts are hidden from the app.',
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: _featured,
                  onChanged: (value) => setState(() => _featured = value),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AdminTheme.pink,
                  title: Text(
                    'Featured',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    'Featured items are promoted on the home feed.',
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

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }
}
