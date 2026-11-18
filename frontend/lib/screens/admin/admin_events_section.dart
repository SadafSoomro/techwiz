import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'admin_shell.dart';

/// Member 6 - Manage Events.
class AdminEventsSection extends StatefulWidget {
  const AdminEventsSection({super.key});

  @override
  State<AdminEventsSection> createState() => _AdminEventsSectionState();
}

class _AdminEventsSectionState extends State<AdminEventsSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic> _counts = {};
  Map<String, dynamic> _pagination = {};

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

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AdminService.events(
      search: _searchController.text.trim(),
      status: _status,
      page: page,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _events = (response['events'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _counts = Map<String, dynamic>.from(response['counts'] ?? {});
        _pagination = Map<String, dynamic>.from(response['pagination'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load events.').toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? event}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EventFormDialog(event: event),
    );
    if (saved == true) _load(page: _page);
  }

  int get _page => (_pagination['page'] as num?)?.toInt() ?? 1;
  int get _pages => (_pagination['pages'] as num?)?.toInt() ?? 1;
  int get _total => (_pagination['total'] as num?)?.toInt() ?? 0;

  Future<void> _delete(Map<String, dynamic> event) async {
    final confirmed = await adminConfirm(
      context,
      title: 'Delete event?',
      message: '"${event['title']}" and its booked tickets will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.deleteEvent(_id(event));
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
      padding: AdminTheme.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Manage Events',
            subtitle:
                '${AdminTheme.compact(_total)} matching of '
                '${AdminTheme.compact(_num(_counts['all']))} events',
            icon: Icons.event_rounded,
            action: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.confirmation_number_rounded, size: 16),
                  label: const Text('View Tickets'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.indigo,
                    side: BorderSide(color: AdminTheme.indigo),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    AdminNavScope.maybeOf(context)?.goTo('tickets');
                  },
                ),
                AdminPrimaryButton(
                  label: 'Add Event',
                  icon: Icons.add_rounded,
                  onPressed: () => _openForm(),
                ),
              ],
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
                icon: Icons.event_note_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['upcoming'])} upcoming',
                color: AdminTheme.green,
                icon: Icons.schedule_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['ongoing'])} ongoing',
                color: AdminTheme.cyan,
                icon: Icons.play_circle_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['completed'])} completed',
                color: AdminTheme.textSecondary,
                icon: Icons.check_circle_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['cancelled'])} cancelled',
                color: AdminTheme.red,
                icon: Icons.cancel_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSearchField(
            controller: _searchController,
            hint: 'Search events by title, city or venue...',
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: 12),
          AdminFilterChips(
            options: const {
              '': 'All status',
              'upcoming': 'Upcoming',
              'ongoing': 'Ongoing',
              'completed': 'Completed',
              'cancelled': 'Cancelled',
            },
            selected: _status,
            onSelected: (value) {
              setState(() => _status = value);
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
    if (_loading) return const AdminLoader(label: 'Loading events...');
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }
    if (_events.isEmpty) {
      return const AdminEmptyState(
        message: 'No events match these filters.',
        icon: Icons.event_busy_rounded,
      );
    }

    return AdminPanel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _events.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AdminTheme.border,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final event = _events[index];
          final status = (event['status'] ?? 'upcoming').toString();
          final price = _num(event['ticket_price']);

          return AdminListRow(
            title: (event['title'] ?? 'Untitled').toString(),
            subtitle:
                '${event['city_name'] ?? ''}'
                '${event['venue_name'] != null ? ' - ${event['venue_name']}' : ''}'
                '  -  ${event['event_date'] ?? ''} ${event['start_time'] ?? ''}',
            onTap: () => _openForm(event: event),
            leading: AdminImageThumbnail(
              imageUrl: (event['image_url'] ?? '').toString(),
              fallbackIcon: Icons.calendar_month_rounded,
              fallbackColor: AdminTheme.pink,
              size: 42,
            ),
            pills: [
              AdminPill(label: status, color: AdminTheme.forStatus(status)),
              AdminPill(
                label: (event['category'] ?? '').toString(),
                color: AdminTheme.indigo,
              ),
              if (_toBool(event['is_featured']))
                AdminPill(
                  label: 'featured',
                  color: AdminTheme.amber,
                  icon: Icons.star_rounded,
                ),
            ],
            trailing: AdminMiniStat(
              label:
                  '${AdminTheme.compact(_num(event['attendees_count']))}/'
                  '${AdminTheme.compact(_num(event['capacity']))} booked',
              value: price > 0
                  ? AdminTheme.money(
                      price,
                      currency: (event['currency'] ?? 'PKR').toString(),
                    )
                  : 'Free',
              color: AdminTheme.green,
              alignEnd: true,
            ),
            menu: PopupMenuButton<String>(
              color: AdminTheme.surfaceAlt,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AdminTheme.textMuted,
              ),
              onSelected: (value) {
                if (value == 'edit') _openForm(event: event);
                if (value == 'delete') _delete(event);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded, size: 17),
                    title: Text('Edit event', style: TextStyle(fontSize: 13)),
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
                      'Delete event',
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
 * add / edit event
 * ========================================================================= */

class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({this.event});

  final Map<String, dynamic>? event;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _category;
  late final TextEditingController _city;
  late final TextEditingController _venue;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _price;
  late final TextEditingController _capacity;
  late final TextEditingController _imageUrl;

  String _status = 'upcoming';
  bool _featured = false;
  bool _busy = false;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event ?? {};
    _title = TextEditingController(text: (e['title'] ?? '').toString());
    _description =
        TextEditingController(text: (e['description'] ?? '').toString());
    _address = TextEditingController(text: (e['address'] ?? '').toString());
    _category = TextEditingController(
      text: (e['category'] ?? 'Fan Convention').toString(),
    );
    _city = TextEditingController(text: (e['city_name'] ?? '').toString());
    _venue = TextEditingController(text: (e['venue_name'] ?? '').toString());
    _date = TextEditingController(text: (e['event_date'] ?? '').toString());
    _time = TextEditingController(
      text: (e['start_time'] ?? '10:00').toString(),
    );
    _price = TextEditingController(text: (e['ticket_price'] ?? '0').toString());
    _capacity = TextEditingController(text: (e['capacity'] ?? '0').toString());
    _imageUrl = TextEditingController(text: (e['image_url'] ?? '').toString());
    _imageUrl.addListener(() => setState(() {}));
    _status = (e['status'] ?? 'upcoming').toString();
    _featured = e['is_featured'] is num
        ? (e['is_featured'] as num) != 0
        : e['is_featured'].toString() == 'true';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    _category.dispose();
    _city.dispose();
    _venue.dispose();
    _date.dispose();
    _time.dispose();
    _price.dispose();
    _capacity.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date.text) ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _date.text = picked.toIso8601String().split('T').first;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'description':
          _description.text.trim().isNotEmpty ? _description.text.trim() : null,
      'address': _address.text.trim().isNotEmpty ? _address.text.trim() : null,
      'category': _category.text.trim(),
      'city_name': _city.text.trim(),
      'venue_name': _venue.text.trim(),
      'event_date': _date.text.trim(),
      'start_time': _time.text.trim(),
      'ticket_price': num.tryParse(_price.text.trim()) ?? 0,
      'capacity': num.tryParse(_capacity.text.trim()) ?? 0,
      'image_url': _imageUrl.text.trim().isNotEmpty ? _imageUrl.text.trim() : null,
      'status': _status,
      'is_featured': _featured,
    };

    final id = (widget.event?['id'] as num?)?.toInt();
    final response = _isEdit && id != null
        ? await AdminService.updateEvent(id, body)
        : await AdminService.createEvent(body);

    if (!mounted) return;
    setState(() => _busy = false);

    if (response['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    adminToast(
      context,
      (response['message'] ?? 'Could not save the event.').toString(),
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
                  _isEdit ? 'Edit Event' : 'Add New Event',
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
                  decoration: const InputDecoration(labelText: 'Event title'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _city,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'City is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _venue,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Venue'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _date,
                        readOnly: true,
                        onTap: _pickDate,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Event date',
                          suffixIcon: Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Date is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _time,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Start time',
                          hintText: '10:00',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _category,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Ticket price',
                          helperText: '0 = free entry',
                          helperStyle: TextStyle(
                            color: AdminTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Capacity'),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _address,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Address / Location',
                    hintText: 'e.g. Hall 4, Expo Centre, Main University Rd',
                  ),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Event Description',
                    hintText: 'Describe schedule, highlights, guests...',
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AdminImageThumbnail(
                      imageUrl: _imageUrl.text.trim(),
                      fallbackIcon: Icons.calendar_month_rounded,
                      fallbackColor: AdminTheme.pink,
                      size: 52,
                      radius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrl,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Banner Image URL or Asset Path',
                          prefixIcon: Icon(Icons.image_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  dropdownColor: AdminTheme.surfaceAlt,
                  style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12.5),
                  decoration: const InputDecoration(
                    labelText: 'Choose Bundled Event Banner (Optional)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Custom / manual path')),
                    DropdownMenuItem(value: 'assets/images/events/anime_expo_2025.jpg', child: Text('Anime Expo 2025')),
                    DropdownMenuItem(value: 'assets/images/events/fan_convention.jpg', child: Text('Fan Convention Banner')),
                    DropdownMenuItem(value: 'assets/images/events/cosplay_meetup.jpg', child: Text('Cosplay Meetup Banner')),
                    DropdownMenuItem(value: 'assets/images/events/comic_con.jpg', child: Text('Comic Con Banner')),
                    DropdownMenuItem(value: 'assets/images/events/screening.jpg', child: Text('Screening Banner')),
                    DropdownMenuItem(value: 'assets/images/events/gaming_tournament.jpg', child: Text('Gaming Tournament Banner')),
                    DropdownMenuItem(value: 'assets/images/events/concert.jpg', child: Text('Concert / Live Banner')),
                    DropdownMenuItem(value: 'assets/images/events/fan_meetup.jpg', child: Text('Fan Meetup Banner')),
                    DropdownMenuItem(value: 'assets/images/events/workshop.jpg', child: Text('Workshop Banner')),
                  ],
                  onChanged: (val) {
                    if (val != null && val.isNotEmpty) {
                      setState(() => _imageUrl.text = val);
                    }
                  },
                ),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: AdminTheme.surfaceAlt,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'upcoming',
                      child: Text('Upcoming'),
                    ),
                    DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'upcoming'),
                ),
                SwitchListTile(
                  value: _featured,
                  onChanged: (value) => setState(() => _featured = value),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminTheme.amber,
                  title: Text(
                    'Featured event',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
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
                        label: _isEdit ? 'Save Changes' : 'Create Event',
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
