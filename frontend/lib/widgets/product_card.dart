import 'package:flutter/material.dart';

import '../models/shop_models.dart';
import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import 'product_image.dart';
import 'shop_animated.dart';
import 'shop_widgets.dart';

/// MEMBER 5 - Merchandise Store
/// Product presentation widgets.
///
/// The cards are deliberately callback-based (rather than reading the provider
/// directly) so they can be reused by the Shop Home rows, the search results,
/// the Wishlist screen and the "related products" list on Product Details.

// ---------------------------------------------------------------------------
// Grid card - the main Shop Home / catalogue tile
// ---------------------------------------------------------------------------
class ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onWishlist;
  final VoidCallback? onAddToCart;

  /// Optional ribbon text ("HOT", "NEW", ...) shown above the image.
  final String? ribbon;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onWishlist,
    this.onAddToCart,
    this.ribbon,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ShopTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------- image -------------------------
            Stack(
              children: [
                ProductImage(
                  imageUrl: product.imageUrl,
                  category: product.category,
                  width: double.infinity,
                  height: 126,
                  radius: 0,
                ),

                // discount badge
                if (product.discountPercent > 0)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: ShopDealBadge(percent: product.discountPercent),
                  ),

                // ribbon (only when there is no discount badge competing)
                if (ribbon != null && product.discountPercent == 0)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: ShopTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ribbon!,
                        style: ShopTheme.label(size: 10).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // wishlist heart
                if (onWishlist != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: ShopWishButton(
                      active: product.isWishlisted,
                      onTap: onWishlist,
                      size: 15,
                    ),
                  ),

                // "in cart" badge
                if (product.quantityInCart > 0)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: ShopTag(
                      label: '${product.quantityInCart} in cart',
                      icon: Icons.shopping_cart_rounded,
                      color: ShopTheme.green,
                    ),
                  ),
              ],
            ),

            // ------------------------- details -------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.fandom.isEmpty ? product.category : product.fandom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ShopTheme.label(size: 10.5).copyWith(
                      color: ShopTheme.categoryColor(product.category),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ShopTheme.body(
                      size: 13,
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w600, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  ShopPriceRow(
                    price: product.price,
                    oldPrice: product.oldPrice,
                    discountPercent: product.discountPercent,
                    currency: product.currency,
                    size: 15,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: ShopRatingRow(
                          rating: product.rating,
                          ratingCount: product.ratingCount,
                          showCount: false,
                        ),
                      ),
                      if (onAddToCart != null) _miniAddButton(context),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ShopStockPill(
                    label: product.stockLabel,
                    stock: product.stock,
                    isDigital: product.isDigital,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniAddButton(BuildContext context) {
    final enabled = product.inStock;

    return GestureDetector(
      onTap: enabled ? onAddToCart : null,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          gradient: enabled ? ShopTheme.buyGradient : null,
          color: enabled ? null : ShopTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.add_shopping_cart_rounded,
          size: 15,
          color: enabled ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini card - used by the auto-scrolling merchandising rows
// ---------------------------------------------------------------------------
class ProductMiniCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final double width;
  final bool animated;

  const ProductMiniCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 150,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: ShopTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProductImage(
                  imageUrl: product.imageUrl,
                  category: product.category,
                  width: width,
                  height: 108,
                  radius: 0,
                  animated: animated,
                ),
                if (product.discountPercent > 0)
                  Positioned(
                    left: 7,
                    top: 7,
                    child: ShopDealBadge(
                      percent: product.discountPercent,
                      compact: true,
                    ),
                  ),
                if (product.quantityInCart > 0)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: ShopTheme.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ShopTheme.body(
                      size: 12,
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w600, height: 1.22),
                  ),
                  const SizedBox(height: 5),
                  ShopPriceRow(
                    price: product.price,
                    currency: product.currency,
                    size: 14,
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

// ---------------------------------------------------------------------------
// Wide card - Wishlist / Cart / search results layout
// ---------------------------------------------------------------------------
class ProductWideCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onWishlist;
  final VoidCallback? onAddToCart;

  /// Extra content rendered under the price (e.g. a price-drop banner or a
  /// quantity stepper supplied by the Cart screen).
  final Widget? footer;
  final Widget? trailing;

  const ProductWideCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onWishlist,
    this.onAddToCart,
    this.footer,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleOnTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: ShopTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    imageUrl: product.imageUrl,
                    category: product.category,
                    width: 84,
                    height: 84,
                    radius: 13,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    ShopTheme.body(
                                      size: 13.5,
                                      color: Colors.white,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                              ),
                            ),
                            if (onWishlist != null)
                              ShopWishButton(
                                active: product.isWishlisted,
                                onTap: onWishlist,
                                size: 15,
                                filled: false,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ShopTag(label: product.category),
                            if (product.fandom.isNotEmpty)
                              ShopTag(
                                label: product.fandom,
                                color: ShopTheme.accent,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ShopRatingRow(
                          rating: product.rating,
                          ratingCount: product.ratingCount,
                        ),
                        const SizedBox(height: 6),
                        ShopPriceRow(
                          price: product.price,
                          oldPrice: product.oldPrice,
                          discountPercent: product.discountPercent,
                          currency: product.currency,
                          size: 16,
                        ),
                        const SizedBox(height: 6),
                        ShopStockPill(
                          label: product.stockLabel,
                          stock: product.stock,
                          isDigital: product.isDigital,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 10), footer!],
              if (onAddToCart != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ShopOutlineButton(
                    label: product.quantityInCart > 0
                        ? 'In cart (${product.quantityInCart}) - add more'
                        : 'Add to Cart',
                    icon: Icons.add_shopping_cart_rounded,
                    onPressed: product.inStock ? onAddToCart : null,
                    height: 42,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton placeholder shown while the catalogue loads
// ---------------------------------------------------------------------------
class ProductCardSkeleton extends StatefulWidget {
  const ProductCardSkeleton({super.key});

  @override
  State<ProductCardSkeleton> createState() => _ProductCardSkeletonState();
}

class _ProductCardSkeletonState extends State<ProductCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.05 + 0.06 * _controller.value;

        return Container(
          decoration: BoxDecoration(
            color: ShopTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 126,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: alpha),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(widthFactor: 0.45, alpha: alpha),
                    const SizedBox(height: 8),
                    _bar(widthFactor: 0.9, alpha: alpha),
                    const SizedBox(height: 6),
                    _bar(widthFactor: 0.6, alpha: alpha),
                    const SizedBox(height: 10),
                    _bar(widthFactor: 0.35, alpha: alpha, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bar({
    required double widthFactor,
    required double alpha,
    double height = 9,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha + 0.04),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
