import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/shop_models.dart';
import '../providers/shop_provider.dart';
import '../theme/shop_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_animated.dart';
import '../widgets/shop_scaffold.dart';
import '../widgets/shop_widgets.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';

/// MEMBER 5 - Merchandise Store
/// Order Success: the "Order Placed!" confirmation from the design board with
/// the order code, the bill and the View Orders / Continue Shopping actions.
class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();

    return ShopScaffold(
      title: 'Order Success',
      subtitle: 'Order ${order.shortCode}',
      showBackButton: false,
      actions: [
        ShopHeaderAction(
          icon: Icons.shopping_bag_rounded,
          tooltip: 'Cart',
          badgeCount: provider.cartQuantity,
          onTap: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
        children: [
          // --------------------------- hero ---------------------------
          BounceIn(
            child: Column(
              children: [
                const FloatingBox(
                  amplitude: 7,
                  period: Duration(milliseconds: 2600),
                  child: PulseGlow(
                    color: ShopTheme.green,
                    minRadius: 14,
                    maxRadius: 34,
                    child: _SuccessCheck(),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Order Placed!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your order has been placed successfully.',
                  textAlign: TextAlign.center,
                  style: ShopTheme.body(size: 14),
                ),
                const SizedBox(height: 16),

                // ----------------------- order code chip -----------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ShopTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ShopTheme.gold.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.confirmation_number_rounded,
                        size: 16,
                        color: ShopTheme.gold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.shortCode,
                        style: GoogleFonts.outfit(
                          color: ShopTheme.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ShopTag(label: order.statusLabel, color: ShopTheme.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // --------------------------- bill ---------------------------
          _Card(
            title: 'Bill summary',
            icon: Icons.receipt_long_rounded,
            children: [
              ...order.items.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      ProductImage(
                        imageUrl: line.imageUrl,
                        width: 40,
                        height: 40,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ShopTheme.body(
                                size: 12.5,
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
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
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 12),
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
                valueColor: order.shippingFee == 0 ? ShopTheme.green : null,
              ),
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 14),
              ShopBillRow(
                label: 'Total paid (simulated)',
                value: ShopTheme.formatPrice(
                  order.total,
                  currency: order.currency,
                ),
                emphasised: true,
                valueColor: ShopTheme.gold,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ------------------------- delivery -------------------------
          _Card(
            title: 'Order information',
            icon: Icons.info_outline_rounded,
            children: [
              ShopBillRow(
                label: 'Placed',
                value: order.placedAgo.isEmpty ? 'just now' : order.placedAgo,
              ),
              ShopBillRow(label: 'Payment', value: order.paymentMethod),
              if (order.shippingName != null && order.shippingName!.isNotEmpty)
                ShopBillRow(label: 'Recipient', value: order.shippingName!),
              if (order.shippingCity != null && order.shippingCity!.isNotEmpty)
                ShopBillRow(label: 'City', value: order.shippingCity!),
              if (order.shippingAddress != null &&
                  order.shippingAddress!.isNotEmpty)
                ShopBillRow(label: 'Address', value: order.shippingAddress!),
              if (order.note != null && order.note!.isNotEmpty)
                ShopBillRow(label: 'Note', value: order.note!),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ShopTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: ShopTheme.green,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'This is a simulated checkout for the Fandom Verse project - no '
                    'payment was processed and no delivery will be made. Your order '
                    'is saved so you can review the bill any time.',
                    style: ShopTheme.label(size: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --------------------------- actions ---------------------------
          Row(
            children: [
              Expanded(
                child: ShopOutlineButton(
                  label: 'View Orders',
                  icon: Icons.receipt_long_rounded,
                  height: 50,
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShopPrimaryButton(
                  label: 'Continue',
                  icon: Icons.storefront_rounded,
                  height: 50,
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                    (route) => route.isFirst,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: order.buyAgainProductId == null
                ? null
                : () => _buyAgain(context),
            icon: const Icon(
              Icons.replay_rounded,
              size: 17,
              color: ShopTheme.accent,
            ),
            label: Text(
              'Buy these items again',
              style: GoogleFonts.inter(
                color: ShopTheme.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buyAgain(BuildContext context) async {
    final provider = context.read<ShopProvider>();
    final message = await provider.buyAgain(order.buyAgainProductId!);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? provider.errorMessage ?? 'Could not add the item',
        ),
        backgroundColor: message == null
            ? ShopTheme.red
            : ShopTheme.surfaceUltra,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View cart',
          textColor: ShopTheme.gold,
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated success tick - the ring sweeps in, then the tick draws itself
// ---------------------------------------------------------------------------
class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final ringProgress = Curves.easeOutCubic.transform(
            (_controller.value / 0.6).clamp(0.0, 1.0),
          );
          final tickProgress = Curves.easeOutCubic.transform(
            ((_controller.value - 0.5) / 0.5).clamp(0.0, 1.0),
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              // pulsing outer halo
              Transform.scale(
                scale: 1 + 0.12 * ringProgress,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ShopTheme.green.withValues(alpha: 0.10),
                  ),
                ),
              ),

              // gradient ring
              SizedBox(
                width: 104,
                height: 104,
                child: CircularProgressIndicator(
                  value: ringProgress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    ShopTheme.green,
                  ),
                ),
              ),

              // the tick
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ShopTheme.green, Color(0xFF059669)],
                  ),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(38, 38),
                    painter: _TickPainter(progress: tickProgress),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Draws the check mark stroke by stroke.
class _TickPainter extends CustomPainter {
  final double progress;

  const _TickPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final start = Offset(size.width * 0.16, size.height * 0.54);
    final middle = Offset(size.width * 0.40, size.height * 0.78);
    final end = Offset(size.width * 0.86, size.height * 0.24);

    final path = Path()..moveTo(start.dx, start.dy);

    // First half of the progress draws start -> middle, the second half
    // middle -> end.
    if (progress <= 0.5) {
      final t = progress / 0.5;
      path.lineTo(
        start.dx + (middle.dx - start.dx) * t,
        start.dy + (middle.dy - start.dy) * t,
      );
    } else {
      final t = (progress - 0.5) / 0.5;
      path.lineTo(middle.dx, middle.dy);
      path.lineTo(
        middle.dx + (end.dx - middle.dx) * t,
        middle.dy + (end.dy - middle.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TickPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Simple titled card used for the bill / info blocks
// ---------------------------------------------------------------------------
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: ShopTheme.primary),
              const SizedBox(width: 8),
              Text(title, style: ShopTheme.title(size: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
