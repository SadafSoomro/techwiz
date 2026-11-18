import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';

/// Member 6 - Manage User Orders & Shipments.
/// Allows administrators to view all customer orders, filter by status,
/// update status (Pending, Shipped, Delivered, Cancelled), and delete orders.
class AdminOrdersSection extends StatefulWidget {
  const AdminOrdersSection({super.key});

  @override
  State<AdminOrdersSection> createState() => _AdminOrdersSectionState();
}

class _AdminOrdersSectionState extends State<AdminOrdersSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _orders = [];
  int _totalOrders = 0;
  int _page = 1;

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

    final response = await AdminService.orders(
      query: _searchController.text.trim(),
      status: _status,
      page: page,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _orders = (response['orders'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _totalOrders = (response['total'] as num? ?? 0).toInt();
        _page = (response['page'] as num? ?? 1).toInt();
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load orders.').toString();
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
      case 'delivered':
        return const Color(0xFF10B981); // Emerald Green
      case 'shipped':
      case 'dispatched':
        return const Color(0xFF06B6D4); // Cyan
      case 'processing':
        return const Color(0xFF6366F1); // Indigo
      case 'pending':
      case 'placed':
        return const Color(0xFFF59E0B); // Amber
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'shipped':
      case 'dispatched':
        return Icons.local_shipping_rounded;
      case 'processing':
        return Icons.inventory_2_rounded;
      case 'pending':
      case 'placed':
        return Icons.schedule_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final response = await AdminService.updateOrderStatus(orderId, newStatus);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order updated to "${newStatus.toUpperCase()}"',
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
            response['message'] ?? 'Failed to update order status',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmDelete(int orderId, String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Delete Order #$code?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'This will permanently remove this customer order from the database.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await AdminService.deleteOrder(orderId);
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
        _load(page: _page);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Delete failed', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final items = (order['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final status = (order['status'] ?? 'pending').toString();
    final orderId = (order['id'] as num).toInt();
    final orderCode = (order['order_code'] ?? 'FV-000000').toString();
    final color = _statusColor(status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: AdminTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$orderCode',
                          style: GoogleFonts.rajdhani(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Placed ${order['placed_ago'] ?? 'recently'}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), size: 14, color: color),
                        const SizedBox(width: 5),
                        Text(
                          status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Customer & Shipping Info
              Text(
                'Customer & Shipping',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _infoRow('Customer', order['shipping_name'] ?? order['user_name'] ?? 'Guest Customer'),
                    _infoRow('Email', order['user_email'] ?? 'Not provided'),
                    if ((order['shipping_phone'] ?? '').toString().isNotEmpty)
                      _infoRow('Phone', order['shipping_phone'].toString()),
                    _infoRow(
                      'Address',
                      [
                        order['shipping_address'] ?? '',
                        order['shipping_city'] ?? '',
                      ].where((s) => s.isNotEmpty).join(', '),
                    ),
                    if ((order['payment_method'] ?? '').toString().isNotEmpty)
                      _infoRow('Payment', order['payment_method'].toString()),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ordered Items
              Text(
                'Items (${items.length})',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (ctx, idx) {
                    final it = items[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: it['image_url'] != null && (it['image_url'] as String).isNotEmpty
                                ? Image.network(
                                    it['image_url'],
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 44,
                                      height: 44,
                                      color: Colors.white12,
                                      child: const Icon(Icons.shopping_bag, size: 20, color: Colors.white54),
                                    ),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.white12,
                                    child: const Icon(Icons.shopping_bag, size: 20, color: Colors.white54),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it['name'] ?? 'Product',
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Qty: ${it['quantity'] ?? 1}  •  \$${it['unit_price'] ?? 0}',
                                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${it['line_total'] ?? 0}',
                            style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Total Summary & Quick Actions
              const Divider(color: Colors.white12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Bill', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                  Text(
                    '${order['currency'] ?? 'PKR'} ${order['total'] ?? 0}',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Change Buttons
              Text(
                'Change Order Status',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusButton(ctx, orderId, 'pending', 'Pending', const Color(0xFFF59E0B), status),
                    const SizedBox(width: 8),
                    _statusButton(ctx, orderId, 'processing', 'Processing', const Color(0xFF6366F1), status),
                    const SizedBox(width: 8),
                    _statusButton(ctx, orderId, 'shipped', 'Dispatched', const Color(0xFF06B6D4), status),
                    const SizedBox(width: 8),
                    _statusButton(ctx, orderId, 'delivered', 'Delivered', const Color(0xFF10B981), status),
                    const SizedBox(width: 8),
                    _statusButton(ctx, orderId, 'cancelled', 'Cancelled', const Color(0xFFEF4444), status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext ctx,
    int orderId,
    String targetStatus,
    String label,
    Color color,
    String currentStatus,
  ) {
    final isSelected = currentStatus.toLowerCase() == targetStatus.toLowerCase();
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
        side: BorderSide(color: isSelected ? color : Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () {
        Navigator.of(ctx).pop();
        _updateStatus(orderId, targetStatus);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(targetStatus), size: 14, color: isSelected ? color : Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? color : Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AdminTheme.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF818CF8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders & Shipments',
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$_totalOrders total orders across all users',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                  tooltip: 'Refresh orders',
                  onPressed: () => _load(page: _page),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by Order ID, Customer Name, or City...',
              hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12.5),
              prefixIcon: const Icon(Icons.search, size: 19, color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', ''),
                _filterChip('Placed', 'placed'),
                _filterChip('Pending', 'pending'),
                _filterChip('Processing', 'processing'),
                _filterChip('Shipped', 'shipped'),
                _filterChip('Delivered', 'delivered'),
                _filterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Orders List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _load(page: _page),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inbox_rounded, size: 48, color: Colors.white24),
                                const SizedBox(height: 8),
                                Text(
                                  'No orders found matching this filter',
                                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) {
                              final order = _orders[index];
                              final status = (order['status'] ?? 'pending').toString();
                              final color = _statusColor(status);
                              final orderId = (order['id'] as num).toInt();
                              final orderCode = (order['order_code'] ?? 'FV-000000').toString();

                              return Container(
                                decoration: BoxDecoration(
                                  color: AdminTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showOrderDetails(order),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header Row: Code + Status Badge + Menu
                                          Row(
                                            children: [
                                              Text(
                                                '#$orderCode',
                                                style: GoogleFonts.rajdhani(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.16),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: color.withValues(alpha: 0.45)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(_statusIcon(status), size: 12, color: color),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      status.toUpperCase(),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: color,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, size: 20, color: Colors.white54),
                                                color: AdminTheme.surface,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                onSelected: (val) {
                                                  if (val == 'delete') {
                                                    _confirmDelete(orderId, orderCode);
                                                  } else {
                                                    _updateStatus(orderId, val);
                                                  }
                                                },
                                                itemBuilder: (ctx) => [
                                                  const PopupMenuItem(
                                                    value: 'pending',
                                                    child: Text('Mark as Pending', style: TextStyle(color: Colors.white)),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'processing',
                                                    child: Text('Mark as Processing', style: TextStyle(color: Colors.white)),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'shipped',
                                                    child: Text('Mark as Dispatched', style: TextStyle(color: Colors.white)),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delivered',
                                                    child: Text('Mark as Delivered', style: TextStyle(color: Colors.white)),
                                                  ),
                                                  const PopupMenuDivider(),
                                                  const PopupMenuItem(
                                                    value: 'cancelled',
                                                    child: Text('Cancel Order', style: TextStyle(color: Colors.orangeAccent)),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('Delete Order', style: TextStyle(color: Colors.redAccent)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // Customer & items info
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      order['shipping_name'] ?? order['user_name'] ?? 'Customer',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      order['user_email'] ?? 'No email',
                                                      style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white60),
                                                    ),
                                                    if ((order['shipping_city'] ?? '').toString().isNotEmpty) ...[
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        '📍 ${order['shipping_city']}',
                                                        style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white54),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${order['currency'] ?? 'USD'} ${order['total'] ?? 0}',
                                                    style: GoogleFonts.rajdhani(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF10B981),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.06),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${order['item_count'] ?? 1} items',
                                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Subtle Divider
                                          Container(
                                            height: 1,
                                            color: Colors.white.withValues(alpha: 0.05),
                                          ),
                                          const SizedBox(height: 10),

                                          // Footer: time placed + view details button
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time_rounded, size: 13, color: Colors.white38),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    order['placed_ago'] ?? 'Recently',
                                                    style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white38),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'View details',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: const Color(0xFF818CF8),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 16,
                                                    color: Color(0xFF818CF8),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _status = value);
          _load(page: 1);
        },
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
        side: BorderSide(
          color: selected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
