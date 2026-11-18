import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Manage Event Tickets & Attendee Bookings.
/// Allows administrators to view all purchased tickets, search by attendee or code,
/// verify tickets, and update status (confirmed / cancelled).
class AdminTicketsSection extends StatefulWidget {
  const AdminTicketsSection({super.key});

  @override
  State<AdminTicketsSection> createState() => _AdminTicketsSectionState();
}

class _AdminTicketsSectionState extends State<AdminTicketsSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _tickets = [];
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

    final response = await AdminService.tickets(
      search: _searchController.text.trim(),
      status: _status,
      page: page,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _tickets = (response['tickets'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _counts = Map<String, dynamic>.from(response['counts'] ?? {});
        _pagination = Map<String, dynamic>.from(response['pagination'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load event tickets.').toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(page: 1));
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AdminTheme.green;
      case 'cancelled':
        return AdminTheme.red;
      case 'used':
        return AdminTheme.indigo;
      default:
        return AdminTheme.amber;
    }
  }

  Future<void> _updateTicketStatus(int ticketId, String newStatus) async {
    final response = await AdminService.setTicketStatus(ticketId, newStatus);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket marked as ${newStatus.toUpperCase()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _statusColor(newStatus),
        ),
      );
      _load(page: _page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Failed to update ticket status',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AdminTheme.red,
        ),
      );
    }
  }

  int get _page => (_pagination['page'] as num?)?.toInt() ?? 1;
  int get _pages => (_pagination['pages'] as num?)?.toInt() ?? 1;
  int get _total => (_pagination['total'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AdminTheme.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Event Tickets',
            subtitle:
                '${AdminTheme.compact(_total)} matching of '
                '${AdminTheme.compact((_counts['all'] as num?)?.toInt() ?? _total)} booked passes',
            icon: Icons.confirmation_number_rounded,
            action: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              color: AdminTheme.textSecondary,
              onPressed: () => _load(page: _page),
            ),
          ),
          const SizedBox(height: 16),

          // Stat chips
          _buildStatRow(),
          const SizedBox(height: 16),

          // Search & Filter
          _buildSearchAndFilters(),
          const SizedBox(height: 16),

          // Content list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: TextStyle(color: AdminTheme.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _load(page: 1),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _tickets.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _tickets.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _buildTicketCard(_tickets[i]),
                          ),
          ),
          if (!_loading && _error == null && _pages > 1)
            AdminPager(
              page: _page,
              pages: _pages,
              total: _total,
              onPage: (p) => _load(page: p),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final allCount = _counts['all'] ?? _total;
    final pendingCount = _counts['pending'] ?? 0;
    final confirmedCount = _counts['confirmed'] ?? 0;
    final cancelledCount = _counts['cancelled'] ?? 0;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        AdminPill(
          label: '$allCount total tickets',
          color: AdminTheme.indigo,
          icon: Icons.confirmation_number_rounded,
        ),
        AdminPill(
          label: '$pendingCount pending',
          color: AdminTheme.amber,
          icon: Icons.hourglass_top_rounded,
        ),
        AdminPill(
          label: '$confirmedCount confirmed',
          color: AdminTheme.green,
          icon: Icons.check_circle_rounded,
        ),
        AdminPill(
          label: '$cancelledCount cancelled',
          color: AdminTheme.red,
          icon: Icons.cancel_rounded,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(color: AdminTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search tickets by code, attendee, email, event...',
            hintStyle: TextStyle(color: AdminTheme.textMuted),
            prefixIcon: Icon(Icons.search_rounded, color: AdminTheme.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: AdminTheme.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      _load(page: 1);
                    },
                  )
                : null,
            filled: true,
            fillColor: AdminTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AdminTheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', ''),
              const SizedBox(width: 8),
              _filterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _filterChip('Confirmed', 'confirmed'),
              const SizedBox(width: 8),
              _filterChip('Cancelled', 'cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _status = value);
        _load(page: 1);
      },
      selectedColor: AdminTheme.primary,
      backgroundColor: AdminTheme.surface,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AdminTheme.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AdminTheme.primary : Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final code = (ticket['ticket_code'] ?? 'TICKET').toString();
    final status = (ticket['status'] ?? 'confirmed').toString().toLowerCase();
    final eventTitle = (ticket['event_title'] ?? 'Fandom Event').toString();
    final userName = (ticket['user_name'] ?? 'Attendee').toString();
    final userEmail = (ticket['user_email'] ?? '').toString();
    final seat = ticket['seat_number']?.toString();
    final qty = (ticket['quantity'] as num?)?.toInt() ?? 1;
    final totalPrice = (ticket['total_price'] as num?)?.toDouble() ?? 0.0;
    final currency = (ticket['currency'] ?? 'PKR').toString();
    final bookedAt = (ticket['booked_at'] ?? '').toString();
    final venue = (ticket['venue_name'] ?? ticket['city_name'] ?? '').toString();
    final ticketId = (ticket['id'] as num).toInt();

    final statusColor = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Ticket Code & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_rounded, size: 16, color: AdminTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          code,
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AdminTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, size: 16, color: AdminTheme.textMuted),
                    tooltip: 'Copy Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ticket code $code copied!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Event Title
          Text(
            eventTitle,
            style: GoogleFonts.inter(
              color: AdminTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (venue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: AdminTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    venue,
                    style: TextStyle(color: AdminTheme.textMuted, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),

          // Attendee & Ticket details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTENDEE',
                      style: GoogleFonts.inter(
                        color: AdminTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: TextStyle(color: AdminTheme.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PASSES',
                    style: GoogleFonts.inter(
                      color: AdminTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$qty ${qty == 1 ? "Ticket" : "Tickets"}',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (seat != null)
                    Text(
                      seat,
                      style: TextStyle(color: AdminTheme.amber, fontSize: 11),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AMOUNT',
                    style: GoogleFonts.inter(
                      color: AdminTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalPrice <= 0 ? 'FREE' : '$currency ${totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.rajdhani(
                      color: AdminTheme.green,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (bookedAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Booked: $bookedAt',
              style: TextStyle(color: AdminTheme.textMuted, fontSize: 11),
            ),
          ],

          const SizedBox(height: 14),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status != 'confirmed')
                OutlinedButton.icon(
                  onPressed: () => _updateTicketStatus(ticketId, 'confirmed'),
                  icon: Icon(Icons.check_circle_outline, size: 16, color: AdminTheme.green),
                  label: Text('Confirm', style: TextStyle(color: AdminTheme.green)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AdminTheme.green),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              if (status != 'cancelled') ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _updateTicketStatus(ticketId, 'cancelled'),
                  icon: Icon(Icons.cancel_outlined, size: 16, color: AdminTheme.red),
                  label: Text('Cancel', style: TextStyle(color: AdminTheme.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AdminTheme.red),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 56, color: AdminTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'No event tickets found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bookings from attendees will appear here.',
            style: TextStyle(color: AdminTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
