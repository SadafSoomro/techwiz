import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/shop_models.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_animated.dart';
import '../widgets/shop_scaffold.dart';
import '../widgets/shop_widgets.dart';
import 'product_details_screen.dart';
import 'shop_screen.dart';

/// MEMBER 5 - Merchandise Store
/// Orders: the SRS "purchase history" - every simulated order with its bill,
/// plus the price alert history the wishlist produced.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ShopProvider>();
      provider.loadOrders();
      provider.loadPriceAlerts();
    });
  }

  Future<void> _openOrder(Order order) async {
    final provider = context.read<ShopProvider>();
    final full = await provider.orderDetails(order.id);

    if (!mounted || full == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OrderDetailSheet(
        order: full,
        onBuyAgain: (productId) async {
          Navigator.of(context).pop();
          final message = await provider.buyAgain(productId);

          if (!mounted) return;
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(
                message ??
                    provider.errorMessage ??
                    'Could not add the item back to your cart',
              ),
              backgroundColor: message == null
                  ? ShopTheme.red
                  : ShopTheme.surfaceUltra,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        onDelete: () async {
          Navigator.of(context).pop();
          final message = await provider.deleteOrder(order.id);

          if (!mounted) return;
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(
                message ?? provider.errorMessage ?? 'Order removed',
              ),
              backgroundColor: ShopTheme.surfaceUltra,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final orders = provider.orders;

    return ShopScaffold(
      title: 'My Orders',
      subtitle: orders.isEmpty
          ? 'Your purchase history'
          : '${orders.length} order${orders.length == 1 ? '' : 's'} - '
                '${ShopTheme.formatPrice(provider.totalSpent)} spent',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () async {
            await provider.loadOrders();
            await provider.loadPriceAlerts();
          },
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
      child: Column(
        children: [
          // ---------------------------- tabs ----------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                ShopFilterChip(
                  label: 'Purchase history',
                  selected: _tab == 0,
                  icon: Icons.receipt_long_rounded,
                  count: orders.length,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                ShopFilterChip(
                  label: 'Price alerts',
                  selected: _tab == 1,
                  icon: Icons.trending_down_rounded,
                  accentColor: ShopTheme.green,
                  count: provider.priceAlerts.length,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? _buildOrders(provider, orders)
                : _buildAlerts(provider),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildOrders(ShopProvider provider, List<Order> orders) {
    if (provider.loading && orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ShopTheme.primary),
      );
    }

    if (orders.isEmpty) {
      return ShopEmptyState(
        title: 'No orders yet',
        message:
            'Once you confirm a checkout the order and its bill are saved here '
            'so you can review your purchase history.',
        icon: Icons.receipt_long_rounded,
        actionLabel: 'Browse the shop',
        onAction: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ShopScreen())),
      );
    }

    return RefreshIndicator(
      color: ShopTheme.primary,
      onRefresh: () => provider.loadOrders(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
        children: [
          // ------------------------ summary tiles ------------------------
          Row(
            children: [
              Expanded(
                child: ShopStatTile(
                  label: 'Orders',
                  value: '${orders.length}',
                  counterValue: orders.length,
                  icon: Icons.receipt_long_rounded,
                  color: ShopTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShopStatTile(
                  label: 'Total spent',
                  value: ShopTheme.formatPrice(provider.totalSpent),
                  icon: Icons.payments_rounded,
                  color: ShopTheme.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          ...orders.map(
            (order) => BounceIn(
              child: _OrderCard(order: order, onTap: () => _openOrder(order)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(ShopProvider provider) {
    final alerts = provider.priceAlerts;

    if (alerts.isEmpty) {
      return ShopEmptyState(
        title: 'No price alerts yet',
        message:
            'Add products to your wishlist and we will watch their prices. Every '
            'drop shows up here and as a notification.',
        icon: Icons.trending_down_rounded,
        color: ShopTheme.green,
        actionLabel: 'Open wishlist',
        onAction: () => Navigator.of(context).pop(),
      );
    }

    return RefreshIndicator(
      color: ShopTheme.green,
      onRefresh: () => provider.loadPriceAlerts(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ShopTheme.green.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ShopTheme.green.withValues(alpha: 0.34),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 18,
                  color: ShopTheme.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${alerts.length} price drop alert'
                    '${alerts.length == 1 ? '' : 's'} - these were also delivered '
                    'as in-app notifications.',
                    style: ShopTheme.label(size: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ScaleOnTap(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailsScreen(productId: alert.productId),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: ShopTheme.card(
                    borderColor: ShopTheme.green.withValues(alpha: 0.28),
                  ),
                  child: Row(
                    children: [
                      ProductImage(
                        imageUrl: alert.imageUrl,
                        width: 56,
                        height: 56,
                        radius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ShopTheme.body(
                                size: 12.5,
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  ShopTheme.formatPrice(
                                    alert.oldPrice,
                                    currency: alert.currency,
                                  ),
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textMuted,
                                    fontSize: 11.5,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ShopTheme.formatPrice(
                                    alert.newPrice,
                                    currency: alert.currency,
                                  ),
                                  style: ShopTheme.price(size: 13.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                ShopDealBadge(
                                  label: '-${alert.dropPercent}%',
                                  compact: true,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Save ${ShopTheme.formatPrice(alert.dropAmount, currency: alert.currency)}',
                                  style: GoogleFonts.inter(
                                    color: ShopTheme.green,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  alert.createdAgo,
                                  style: ShopTheme.label(size: 9.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order list card
// ---------------------------------------------------------------------------
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color get _statusColor {
    switch (order.status) {
      case 'delivered':
        return ShopTheme.green;
      case 'cancelled':
        return ShopTheme.red;
      default:
        return ShopTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleOnTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: ShopTheme.card(),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      order.status == 'delivered'
                          ? Icons.check_circle_rounded
                          : Icons.local_shipping_rounded,
                      size: 19,
                      color: _statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.shortCode,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.placedAgo.isEmpty ? ShopTheme.prettyDate(order.placedAt) : order.placedAgo}'
                          '  -  ${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                          style: ShopTheme.label(size: 10.5),
                        ),
                      ],
                    ),
                  ),
                  ShopTag(label: order.statusLabel, color: _statusColor),
                ],
              ),
              const SizedBox(height: 12),

              // ---------------------- item preview ----------------------
              if (order.previewName != null)
                Row(
                  children: [
                    ProductImage(
                      imageUrl: order.previewImage,
                      width: 46,
                      height: 46,
                      radius: 11,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.previewName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ShopTheme.body(
                              size: 12.5,
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (order.additionalItems > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                '+ ${order.additionalItems} more item'
                                '${order.additionalItems == 1 ? '' : 's'}',
                                style: ShopTheme.label(size: 10.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total', style: ShopTheme.label(size: 10)),
                        Text(
                          ShopTheme.formatPrice(
                            order.total,
                            currency: order.currency,
                          ),
                          style: ShopTheme.price(size: 16),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.discount > 0)
                    ShopTag(
                      label:
                          'Saved ${ShopTheme.formatPrice(order.discount, currency: order.currency)}',
                      icon: Icons.savings_rounded,
                      color: ShopTheme.green,
                    ),
                  const Spacer(),
                  Text('View bill', style: ShopTheme.label(size: 11)),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order detail bottom sheet
// ---------------------------------------------------------------------------
class _OrderDetailSheet extends StatelessWidget {
  final Order order;
  final ValueChanged<int> onBuyAgain;
  final VoidCallback onDelete;

  const _OrderDetailSheet({
    required this.order,
    required this.onBuyAgain,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            // grab handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${order.shortCode}',
                          style: ShopTheme.title(size: 18),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order.placedAgo.isEmpty
                              ? ShopTheme.prettyDateTime(order.placedAt)
                              : order.placedAgo,
                          style: ShopTheme.label(size: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                children: [
                  Row(
                    children: [
                      ShopTag(
                        label: order.statusLabel,
                        icon: Icons.check_circle_rounded,
                        color: ShopTheme.green,
                      ),
                      const SizedBox(width: 7),
                      ShopTag(
                        label: order.paymentMethod,
                        icon: Icons.payments_outlined,
                        color: ShopTheme.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text('Items ordered', style: ShopTheme.title(size: 15)),
                  const SizedBox(height: 10),
                  ...order.items.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Row(
                        children: [
                          ProductImage(
                            imageUrl: line.imageUrl,
                            width: 46,
                            height: 46,
                            radius: 11,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: ShopTheme.body(
                                    size: 12.5,
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${line.quantity} x '
                                  '${ShopTheme.formatPrice(line.unitPrice, currency: order.currency)}',
                                  style: ShopTheme.label(size: 10.5),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            ShopTheme.formatPrice(
                              line.lineTotal,
                              currency: order.currency,
                            ),
                            style: ShopTheme.price(size: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: ShopTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ShopTheme.primary.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Column(
                      children: [
                        ShopBillRow(
                          label: 'Subtotal (${order.itemCount} items)',
                          value: ShopTheme.formatPrice(
                            order.subtotal,
                            currency: order.currency,
                          ),
                        ),
                        if (order.discount > 0)
                          ShopBillRow(
                            label:
                                'Discount'
                                '${order.promoCode != null ? ' (${order.promoCode})' : ''}',
                            value:
                                '- ${ShopTheme.formatPrice(order.discount, currency: order.currency)}',
                            valueColor: ShopTheme.green,
                          ),
                        ShopBillRow(
                          label: 'Shipping',
                          value: order.shippingFee == 0
                              ? 'Free'
                              : ShopTheme.formatPrice(
                                  order.shippingFee,
                                  currency: order.currency,
                                ),
                          valueColor: order.shippingFee == 0
                              ? ShopTheme.green
                              : null,
                        ),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 14,
                        ),
                        ShopBillRow(
                          label: 'Total paid',
                          value: ShopTheme.formatPrice(
                            order.total,
                            currency: order.currency,
                          ),
                          emphasised: true,
                          valueColor: ShopTheme.gold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (order.shippingName != null ||
                      order.shippingAddress != null) ...[
                    Text('Delivery details', style: ShopTheme.title(size: 15)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: ShopTheme.card(),
                      child: Column(
                        children: [
                          if (order.shippingName != null)
                            ShopBillRow(
                              label: 'Recipient',
                              value: order.shippingName!,
                            ),
                          if (order.shippingPhone != null &&
                              order.shippingPhone!.isNotEmpty)
                            ShopBillRow(
                              label: 'Phone',
                              value: order.shippingPhone!,
                            ),
                          if (order.shippingCity != null)
                            ShopBillRow(
                              label: 'City',
                              value: order.shippingCity!,
                            ),
                          if (order.shippingAddress != null)
                            ShopBillRow(
                              label: 'Address',
                              value: order.shippingAddress!,
                            ),
                          if (order.note != null && order.note!.isNotEmpty)
                            ShopBillRow(label: 'Note', value: order.note!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      if (order.buyAgainProductId != null)
                        Expanded(
                          child: ShopOutlineButton(
                            label: 'Buy again',
                            icon: Icons.replay_rounded,
                            height: 48,
                            onPressed: () =>
                                onBuyAgain(order.buyAgainProductId!),
                          ),
                        ),
                      if (order.buyAgainProductId != null)
                        const SizedBox(width: 10),
                      Expanded(
                        child: ShopOutlineButton(
                          label: 'Delete',
                          icon: Icons.delete_outline_rounded,
                          color: ShopTheme.red,
                          height: 48,
                          onPressed: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
