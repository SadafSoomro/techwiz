import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/shop_models.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_animated.dart';
import '../widgets/shop_scaffold.dart';
import '../widgets/shop_widgets.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import 'shop_screen.dart';

/// MEMBER 5 - Merchandise Store
/// Wishlist: saved products, the live price-drop alerts the SRS asks for,
/// running totals and a one-tap "move to cart".
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ShopProvider>();
      // Detection runs first so the alerts are fresh when the screen paints.
      await provider.checkPriceAlerts();
      await provider.loadPriceAlerts();
    });
  }

  Future<void> _checkPrices({bool announce = true}) async {
    setState(() => _checking = true);

    final provider = context.read<ShopProvider>();
    final result = await provider.checkPriceAlerts();
    await provider.loadPriceAlerts();

    if (!mounted) return;
    setState(() => _checking = false);

    if (announce) _snack(result.message, isDrop: result.count > 0);
  }

  Future<void> _moveToCart(WishlistItem item) async {
    final provider = context.read<ShopProvider>();
    final message = await provider.addToCart(item.product);

    if (!mounted) return;

    if (message == null) {
      _snack(provider.errorMessage ?? 'Could not move the item', isError: true);
      return;
    }
    _snack(message, action: 'View cart', onAction: () => _openCart());
  }

  Future<void> _remove(WishlistItem item) async {
    final provider = context.read<ShopProvider>();
    final message = await provider.removeFromWishlist(item.product.id);

    if (!mounted) return;

    if (message == null) {
      _snack(
        provider.errorMessage ?? 'Could not remove the item',
        isError: true,
      );
      return;
    }
    _snack('${item.product.name} removed from your wishlist');
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear wishlist?', style: ShopTheme.title(size: 18)),
        content: Text(
          'This removes every saved product from your wishlist. '
          'Your cart and orders are not affected.',
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
              'Clear all',
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
    final message = await provider.clearWishlist();

    if (!mounted) return;
    _snack(message ?? provider.errorMessage ?? 'Wishlist cleared');
  }

  void _openCart() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CartScreen()));

  void _snack(
    String message, {
    bool isError = false,
    bool isDrop = false,
    String? action,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isDrop) ...[
              const Icon(
                Icons.trending_down_rounded,
                color: ShopTheme.green,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? ShopTheme.red : ShopTheme.surfaceUltra,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action == null
            ? null
            : SnackBarAction(
                label: action,
                textColor: ShopTheme.gold,
                onPressed: onAction ?? () {},
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final items = provider.wishlist;

    return ShopScaffold(
      title: 'Wishlist',
      subtitle: '${items.length} saved item${items.length == 1 ? '' : 's'}',
      actions: [
        IconButton(
          tooltip: 'Check for price drops',
          onPressed: _checking ? null : () => _checkPrices(),
          icon: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ShopTheme.green,
                  ),
                )
              : const Icon(Icons.trending_down_rounded, color: ShopTheme.green),
        ),
        ShopHeaderAction(
          icon: Icons.shopping_bag_rounded,
          tooltip: 'Cart',
          badgeCount: provider.cartQuantity,
          onTap: _openCart,
        ),
      ],
      child: provider.loading && items.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: ShopTheme.secondary),
            )
          : items.isEmpty
          ? ShopEmptyState(
              title: 'Your wishlist is empty',
              message:
                  'Tap the heart on any product and we will keep an eye on '
                  'its price for you - you get an alert the moment it drops.',
              icon: Icons.favorite_border_rounded,
              actionLabel: 'Browse the shop',
              onAction: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ShopScreen())),
            )
          : _buildList(provider, items),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildList(ShopProvider provider, List<WishlistItem> items) {
    final drops = items.where((item) => item.hasPriceDrop).toList();

    return RefreshIndicator(
      color: ShopTheme.secondary,
      onRefresh: () => _checkPrices(announce: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
        children: [
          // ------------------------ summary tiles ------------------------
          Row(
            children: [
              Expanded(
                child: ShopStatTile(
                  label: 'Saved items',
                  value: '${items.length}',
                  counterValue: items.length,
                  icon: Icons.favorite_rounded,
                  color: ShopTheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShopStatTile(
                  label: 'Total value',
                  value: ShopTheme.formatPrice(provider.wishlistValue),
                  icon: Icons.payments_rounded,
                  color: ShopTheme.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ShopStatTile(
                  label: 'Deal savings',
                  value: ShopTheme.formatPrice(provider.wishlistSavings),
                  icon: Icons.savings_rounded,
                  color: ShopTheme.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShopStatTile(
                  label: 'Price drops',
                  value: '${drops.length}',
                  counterValue: drops.length,
                  icon: Icons.trending_down_rounded,
                  color: ShopTheme.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---------------------- price drop banner ----------------------
          if (drops.isNotEmpty) ...[
            _PriceDropHeader(count: drops.length),
            const SizedBox(height: 12),
          ],

          // --------------------------- items ---------------------------
          ...items.map(
            (item) => BounceIn(
              child: ProductWideCard(
                product: item.product,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(
                      productId: item.product.id,
                      initialProduct: item.product,
                    ),
                  ),
                ),
                onWishlist: () => _remove(item),
                footer: _buildFooter(item),
                trailing: Column(
                  children: [
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => _remove(item),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: ShopTheme.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // --------------------------- actions ---------------------------
          ShopOutlineButton(
            label: 'Move all to cart',
            icon: Icons.shopping_cart_checkout_rounded,
            onPressed: () => _moveAllToCart(items),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _clearAll,
            icon: const Icon(
              Icons.delete_sweep_rounded,
              size: 17,
              color: ShopTheme.red,
            ),
            label: Text(
              'Clear wishlist',
              style: GoogleFonts.inter(
                color: ShopTheme.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Price-drop strip / "saved N ago" strip shown under a wishlist item.
  Widget _buildFooter(WishlistItem item) {
    if (item.hasPriceDrop && item.priceDrop != null) {
      final drop = item.priceDrop!;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ShopTheme.green.withValues(alpha: 0.18),
              ShopTheme.accent.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ShopTheme.green.withValues(alpha: 0.36)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.trending_down_rounded,
              size: 17,
              color: ShopTheme.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price dropped ${drop.dropPercent}%',
                    style: GoogleFonts.inter(
                      color: ShopTheme.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'was ${ShopTheme.formatPrice(drop.oldPrice, currency: drop.currency)} '
                    '- now ${ShopTheme.formatPrice(drop.newPrice, currency: drop.currency)}',
                    style: ShopTheme.label(size: 10.5),
                  ),
                ],
              ),
            ),
            ShopPrimaryButton(
              label: 'Grab it',
              height: 34,
              expanded: false,
              gradient: LinearGradient(
                colors: [
                  ShopTheme.green,
                  ShopTheme.green.withValues(alpha: 0.78),
                ],
              ),
              onPressed: () => _moveToCart(item),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 5),
        Text(
          item.savedAgo.isEmpty ? 'Saved' : 'Saved ${item.savedAgo}',
          style: ShopTheme.label(size: 10.5),
        ),
        const Spacer(),
        if (item.priceChange != 0)
          Text(
            item.priceChange < 0
                ? 'Price fell since you saved it'
                : 'Price went up',
            style: ShopTheme.label(size: 10.5).copyWith(
              color: item.priceChange < 0 ? ShopTheme.green : ShopTheme.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Future<void> _moveAllToCart(List<WishlistItem> items) async {
    final provider = context.read<ShopProvider>();
    var added = 0;
    var lastError = '';

    for (final item in items) {
      if (!item.product.inStock) continue;

      final message = await provider.addToCart(item.product);
      if (message != null) {
        added++;
      } else {
        lastError = provider.errorMessage ?? '';
      }
    }

    if (!mounted) return;

    if (added == 0) {
      _snack(
        lastError.isEmpty ? 'Nothing could be added' : lastError,
        isError: true,
      );
      return;
    }
    _snack(
      '$added item${added == 1 ? '' : 's'} added to your cart',
      action: 'View cart',
      onAction: _openCart,
    );
  }
}

// ---------------------------------------------------------------------------
// Price drop header banner
// ---------------------------------------------------------------------------
class _PriceDropHeader extends StatelessWidget {
  final int count;

  const _PriceDropHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            ShopTheme.green.withValues(alpha: 0.22),
            ShopTheme.accent.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShopTheme.green.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          FloatingBox(
            amplitude: 4,
            period: const Duration(milliseconds: 2400),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: ShopTheme.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.trending_down_rounded,
                color: ShopTheme.green,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count price drop${count == 1 ? '' : 's'} on your wishlist',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your wishlist is being watched - these items are cheaper than '
                  'when you saved them.',
                  style: ShopTheme.label(size: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
