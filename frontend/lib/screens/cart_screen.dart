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
import 'checkout_screen.dart';
import 'product_details_screen.dart';
import 'shop_screen.dart';

/// MEMBER 5 - Merchandise Store
/// Cart: change quantities, remove lines, apply a promo code, see the running
/// bill (subtotal / discount / shipping / total) and continue to checkout.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _applyingPromo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadCart();
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _updateQuantity(CartLine line, int quantity) async {
    final provider = context.read<ShopProvider>();
    final message = await provider.updateCartQuantity(line.productId, quantity);

    if (!mounted) return;

    if (message == null) {
      _snack(
        provider.errorMessage ?? 'Could not update the quantity',
        isError: true,
      );
    }
  }

  Future<void> _remove(CartLine line) async {
    final provider = context.read<ShopProvider>();
    final message = await provider.removeFromCart(line.productId);

    if (!mounted) return;

    if (message == null) {
      _snack(
        provider.errorMessage ?? 'Could not remove the item',
        isError: true,
      );
      return;
    }
    _snack('${line.name} removed from your cart');
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Empty your cart?', style: ShopTheme.title(size: 18)),
        content: Text(
          'Every item will be removed from your cart. Your wishlist stays as it is.',
          style: ShopTheme.body(size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: ShopTheme.label(size: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ShopTheme.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Empty cart',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<ShopProvider>();
    await provider.clearCart();

    if (!mounted) return;
    _snack('Cart cleared');
  }

  Future<void> _applyPromo() async {
    setState(() => _applyingPromo = true);

    final provider = context.read<ShopProvider>();
    provider.setPromoInput(_promoController.text);

    final result = await provider.applyPromo();

    if (!mounted) return;
    setState(() => _applyingPromo = false);

    _snack(result.message, isError: !result.ok);
  }

  void _useCode(String code) {
    _promoController.text = code;
    _applyPromo();
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? ShopTheme.red : ShopTheme.surfaceUltra,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final cart = provider.cart;

    return ShopScaffold(
      title: 'Cart',
      subtitle: cart.isEmpty
          ? 'Nothing here yet'
          : '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} ready to order',
      actions: [
        if (!cart.isEmpty)
          IconButton(
            tooltip: 'Empty cart',
            onPressed: _clear,
            icon: const Icon(Icons.delete_sweep_rounded, color: ShopTheme.red),
          ),
      ],
      bottomBar: cart.isEmpty ? null : _buildBottomBar(provider, cart),
      child: cart.isEmpty
          ? ShopEmptyState(
              title: 'Your cart is empty',
              message:
                  'Add figures, tees or digital art from the shop and they will '
                  'show up here along with your running total.',
              icon: Icons.shopping_bag_outlined,
              actionLabel: 'Start shopping',
              onAction: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ShopScreen())),
            )
          : RefreshIndicator(
              color: ShopTheme.primary,
              onRefresh: () => provider.loadCart(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                children: [
                  // ------------------ free shipping progress ------------------
                  _FreeShippingProgress(cart: cart),
                  const SizedBox(height: 16),

                  // ------------------------ cart lines ------------------------
                  ...cart.items.map(
                    (line) => BounceIn(
                      child: _CartLineTile(
                        line: line,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailsScreen(productId: line.productId),
                          ),
                        ),
                        onQuantityChanged: (value) =>
                            _updateQuantity(line, value),
                        onRemove: () => _remove(line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ------------------------- promo box -------------------------
                  _PromoBox(
                    controller: _promoController,
                    applying: _applyingPromo,
                    message: provider.promoMessage,
                    isError: provider.promoIsError,
                    appliedCode: cart.promoCode,
                    available: provider.promoCodes,
                    onApply: _applyPromo,
                    onUseCode: _useCode,
                    onRemove: () async {
                      await provider.removePromo();
                      _promoController.clear();
                      if (!mounted) return;
                      _snack('Promo code removed');
                    },
                  ),
                  const SizedBox(height: 18),

                  // --------------------------- bill ---------------------------
                  _BillCard(cart: cart, currency: cart.currency),
                  const SizedBox(height: 16),

                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(
                      Icons.remove_shopping_cart_rounded,
                      size: 17,
                      color: ShopTheme.red,
                    ),
                    label: Text(
                      'Empty cart',
                      style: GoogleFonts.inter(
                        color: ShopTheme.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  Widget _buildBottomBar(ShopProvider provider, CartSummary cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total', style: ShopTheme.label(size: 11)),
                Text(
                  ShopTheme.formatPrice(cart.total, currency: cart.currency),
                  style: ShopTheme.price(size: 20),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ShopPrimaryButton(
                label: 'Checkout',
                icon: Icons.lock_outline_rounded,
                height: 48,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Free shipping progress bar
// ---------------------------------------------------------------------------
class _FreeShippingProgress extends StatelessWidget {
  final CartSummary cart;

  const _FreeShippingProgress({required this.cart});

  @override
  Widget build(BuildContext context) {
    final threshold = cart.freeShippingThreshold;
    final remaining = (threshold - (cart.subtotal - cart.discount)).clamp(
      0.0,
      threshold,
    );
    final progress = threshold <= 0
        ? 1.0
        : ((cart.subtotal - cart.discount) / threshold).clamp(0.0, 1.0);

    final unlocked = cart.freeShipping;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShopTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (unlocked ? ShopTheme.green : ShopTheme.primary).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked
                    ? Icons.local_shipping_rounded
                    : Icons.local_shipping_outlined,
                size: 17,
                color: unlocked ? ShopTheme.green : ShopTheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cart.shippingNote.isEmpty
                      ? (unlocked
                            ? 'Free shipping unlocked'
                            : 'Add more for free shipping')
                      : cart.shippingNote,
                  style: GoogleFonts.inter(
                    color: unlocked ? ShopTheme.green : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!unlocked)
                Text(
                  ShopTheme.formatPrice(remaining, currency: cart.currency),
                  style: ShopTheme.label(size: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(
                  unlocked ? ShopTheme.green : ShopTheme.primary,
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
// One cart line
// ---------------------------------------------------------------------------
class _CartLineTile extends StatelessWidget {
  final CartLine line;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartLineTile({
    required this.line,
    required this.onTap,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleOnTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: ShopTheme.card(),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    imageUrl: line.imageUrl,
                    category: line.category,
                    width: 78,
                    height: 78,
                    radius: 13,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ShopTheme.body(
                            size: 13,
                            color: Colors.white,
                          ).copyWith(fontWeight: FontWeight.w600, height: 1.25),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (line.fandom.isNotEmpty)
                              ShopTag(
                                label: line.fandom,
                                color: ShopTheme.accent,
                              ),
                            if (line.discountPercent > 0)
                              ShopDealBadge(
                                percent: line.discountPercent,
                                compact: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ShopPriceRow(
                          price: line.price,
                          oldPrice: line.oldPrice,
                          currency: line.currency,
                          size: 15,
                        ),
                        const SizedBox(height: 5),
                        ShopStockPill(
                          label: line.isDigital ? 'Digital' : 'In stock',
                          stock: line.stock,
                          isDigital: line.isDigital,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ShopQuantityStepper(
                    quantity: line.quantity,
                    max: line.maxQuantity,
                    compact: true,
                    onChanged: onQuantityChanged,
                  ),
                  const Spacer(),
                  Text('Subtotal  ', style: ShopTheme.label(size: 11.5)),
                  Text(
                    ShopTheme.formatPrice(
                      line.lineTotal,
                      currency: line.currency,
                    ),
                    style: ShopTheme.price(size: 15.5),
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
// Promo code box
// ---------------------------------------------------------------------------
class _PromoBox extends StatelessWidget {
  final TextEditingController controller;
  final bool applying;
  final String? message;
  final bool isError;
  final String? appliedCode;
  final List<PromoCode> available;
  final VoidCallback onApply;
  final ValueChanged<String> onUseCode;
  final VoidCallback onRemove;

  const _PromoBox({
    required this.controller,
    required this.applying,
    required this.message,
    required this.isError,
    required this.appliedCode,
    required this.available,
    required this.onApply,
    required this.onUseCode,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShopTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 16,
                color: ShopTheme.gold,
              ),
              const SizedBox(width: 8),
              Text('Promo code', style: ShopTheme.title(size: 14.5)),
            ],
          ),
          const SizedBox(height: 10),

          if (appliedCode != null)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: ShopTheme.green.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ShopTheme.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: ShopTheme.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message ?? appliedCode!,
                            style: GoogleFonts.inter(
                              color: ShopTheme.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove code',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: ShopTheme.red,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 0.6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      isDense: true,
                      filled: true,
                      fillColor: ShopTheme.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: ShopTheme.gold,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ShopPrimaryButton(
                  label: 'Apply',
                  height: 45,
                  expanded: false,
                  loading: applying,
                  gradient: ShopTheme.priceGradient,
                  onPressed: onApply,
                ),
              ],
            ),

          if (message != null && isError) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: ShopTheme.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message!,
                    style: GoogleFonts.inter(
                      color: ShopTheme.red,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (available.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Available codes in this demo',
              style: ShopTheme.label(size: 10.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: available
                  .map(
                    (promo) => GestureDetector(
                      onTap: () => onUseCode(promo.code),
                      child: ShopTag(
                        label: promo.code,
                        icon: Icons.copy_rounded,
                        color: ShopTheme.gold,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The bill
// ---------------------------------------------------------------------------
class _BillCard extends StatelessWidget {
  final CartSummary cart;
  final String currency;

  const _BillCard({required this.cart, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ShopTheme.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: ShopTheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Order summary', style: ShopTheme.title(size: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ShopBillRow(
            label: 'Subtotal (${cart.itemCount} items)',
            value: ShopTheme.formatPrice(cart.subtotal, currency: currency),
          ),
          if (cart.discount > 0)
            ShopBillRow(
              label:
                  'Discount ${cart.promoCode != null ? '(${cart.promoCode})' : ''}',
              value:
                  '- ${ShopTheme.formatPrice(cart.discount, currency: currency)}',
              valueColor: ShopTheme.green,
            ),
          ShopBillRow(
            label: 'Shipping',
            value: cart.shippingFee == 0
                ? 'Free'
                : ShopTheme.formatPrice(cart.shippingFee, currency: currency),
            valueColor: cart.shippingFee == 0 ? ShopTheme.green : null,
            note: cart.shippingFee == 0 && cart.hasPhysical
                ? 'Free shipping applied'
                : (cart.hasDigital && !cart.hasPhysical
                      ? 'Digital order - no shipping'
                      : null),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 18),
          ShopBillRow(
            label: 'Total',
            value: ShopTheme.formatPrice(cart.total, currency: currency),
            emphasised: true,
            valueColor: ShopTheme.gold,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Simulated checkout - no real payment is taken.',
                  style: ShopTheme.label(size: 10.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
