import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/json_utils.dart';
import '../models/shop_models.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_animated.dart';
import '../widgets/shop_scaffold.dart';
import '../widgets/shop_widgets.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';

/// MEMBER 5 - Merchandise Store
/// Product Details: large artwork, price + discount, stock, quantity picker,
/// Add to Cart / Add to Wishlist, the full description and related products.
class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  /// Optional pre-loaded product so the screen paints instantly when the user
  /// taps a card that already has the data.
  final Product? initialProduct;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  List<Product> _related = [];
  double _categoryAverageRating = 0;

  bool _loading = true;
  String? _error;
  int _quantity = 1;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _loading = widget.initialProduct == null;
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<ShopProvider>();
    final result = await provider.loadProductDetails(widget.productId);

    if (!mounted) return;

    if (!result.success || result.data == null) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }

    final json = result.data!;
    final product = parseMap(json['product']);

    setState(() {
      _loading = false;
      _error = null;
      _product = product == null ? null : Product.fromJson(product);
      _related = parseList(json['related'], Product.fromJson);
      _categoryAverageRating = asDouble(json['category_average_rating']);
    });
  }

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null) return;

    setState(() => _adding = true);

    final provider = context.read<ShopProvider>();
    final message = await provider.addToCart(product, quantity: _quantity);

    if (!mounted) return;
    setState(() => _adding = false);

    if (message == null) {
      _snack(provider.errorMessage ?? 'Could not add the item', isError: true);
      return;
    }

    _snack(
      message,
      action: 'View cart',
      onAction: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CartScreen())),
    );
  }

  Future<void> _toggleWishlist() async {
    final product = _product;
    if (product == null) return;

    final provider = context.read<ShopProvider>();
    final result = await provider.toggleWishlist(product);

    if (!mounted) return;

    if (result == null) {
      _snack(
        provider.errorMessage ?? 'Could not update your wishlist',
        isError: true,
      );
      return;
    }

    setState(() {
      _product = product.copyWith(isWishlisted: result);
    });

    _snack(
      result
          ? 'Saved to your wishlist - we will alert you if the price drops'
          : 'Removed from your wishlist',
    );
  }

  void _snack(
    String message, {
    bool isError = false,
    String? action,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    final product = _product;

    return ShopScaffold(
      title: 'Product Details',
      subtitle: product?.category ?? 'Loading...',
      actions: [
        ShopHeaderAction(
          icon: Icons.favorite_rounded,
          tooltip: 'Wishlist',
          badgeCount: provider.wishlistCount,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
        ),
        ShopHeaderAction(
          icon: Icons.shopping_bag_rounded,
          tooltip: 'Cart',
          badgeCount: provider.cartQuantity,
          onTap: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ],
      bottomBar: product == null ? null : _buildBottomBar(product),
      child: _loading && product == null
          ? const Center(
              child: CircularProgressIndicator(color: ShopTheme.primary),
            )
          : _error != null && product == null
          ? ShopErrorState(message: _error!, onRetry: _load)
          : _buildBody(product!),
    );
  }

  // ------------------------------------------------------------------
  // body
  // ------------------------------------------------------------------
  Widget _buildBody(Product product) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        // ------------------------- hero image -------------------------
        BounceIn(
          child: Stack(
            children: [
              ProductImage(
                imageUrl: product.imageUrl,
                category: product.category,
                height: 268,
                width: double.infinity,
                radius: 22,
                animated: true,
              ),
              if (product.discountPercent > 0)
                Positioned(
                  left: 14,
                  top: 14,
                  child: ShopDealBadge(percent: product.discountPercent),
                ),
              if (product.isFeatured)
                const Positioned(
                  right: 14,
                  top: 14,
                  child: ShopTag(
                    label: 'EXCLUSIVE',
                    icon: Icons.workspace_premium_rounded,
                    color: ShopTheme.gold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // --------------------------- title ---------------------------
        Text(product.name, style: ShopTheme.title(size: 22)),
        const SizedBox(height: 8),

        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [
            ShopTag(
              label: product.category,
              icon: ShopTheme.categoryIcon(product.category),
              color: ShopTheme.categoryColor(product.category),
            ),
            if (product.fandom.isNotEmpty)
              ShopTag(label: product.fandom, color: ShopTheme.accent),
            if (product.brand.isNotEmpty)
              ShopTag(
                label: product.brand,
                icon: Icons.verified_rounded,
                color: ShopTheme.green,
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ------------------------ price + stock ------------------------
        Container(
          padding: const EdgeInsets.all(15),
          decoration: ShopTheme.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ShopPriceRow(
                      price: product.price,
                      oldPrice: product.oldPrice,
                      discountPercent: product.discountPercent,
                      currency: product.currency,
                      size: 24,
                    ),
                  ),
                ],
              ),
              if (product.hasDiscount && product.savings > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'You save ${ShopTheme.formatPrice(product.savings, currency: product.currency)}',
                  style: GoogleFonts.inter(
                    color: ShopTheme.green,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  ShopStockPill(
                    label: product.stockLabel,
                    stock: product.stock,
                    isDigital: product.isDigital,
                    compact: false,
                  ),
                  const Spacer(),
                  ShopRatingRow(
                    rating: product.rating,
                    ratingCount: product.ratingCount,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // -------------------------- quantity --------------------------
        if (product.inStock)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: ShopTheme.card(),
            child: Row(
              children: [
                Text(
                  'Quantity',
                  style: ShopTheme.body(size: 13.5, color: Colors.white),
                ),
                const Spacer(),
                ShopQuantityStepper(
                  quantity: _quantity,
                  max: product.isDigital ? 99 : product.stock,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
              ],
            ),
          ),
        if (product.inStock) const SizedBox(height: 16),

        // --------------------------- actions ---------------------------
        Row(
          children: [
            Expanded(
              child: ShopPrimaryButton(
                label: product.inStock ? 'Add to Cart' : 'Out of Stock',
                icon: Icons.add_shopping_cart_rounded,
                loading: _adding,
                onPressed: product.inStock ? _addToCart : null,
              ),
            ),
            const SizedBox(width: 12),
            ShopWishButton(
              active: product.isWishlisted,
              onTap: _toggleWishlist,
              size: 22,
              filled: false,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ------------------------- description -------------------------
        if (product.description.isNotEmpty) ...[
          Text('About this product', style: ShopTheme.title(size: 16)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: ShopTheme.card(),
            child: Text(
              product.description,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // --------------------------- details ---------------------------
        Text('Product details', style: ShopTheme.title(size: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: ShopTheme.card(),
          child: Column(
            children: [
              _DetailRow(label: 'Category', value: product.category),
              _DetailRow(
                label: 'Fandom',
                value: product.fandom.isEmpty ? '-' : product.fandom,
              ),
              _DetailRow(
                label: 'Brand',
                value: product.brand.isEmpty ? '-' : product.brand,
              ),
              _DetailRow(
                label: 'SKU',
                value: product.sku.isEmpty ? '-' : product.sku,
              ),
              _DetailRow(
                label: 'Type',
                value: product.isDigital ? 'Digital download' : 'Physical item',
              ),
              _DetailRow(
                label: 'Availability',
                value: product.isDigital
                    ? 'Unlimited'
                    : '${product.stock} units',
              ),
              _DetailRow(
                label: 'Rating',
                value: product.ratingCount > 0
                    ? '${product.rating.toStringAsFixed(1)} / 5 ($product.ratingCount reviews)'
                    : 'No reviews yet',
              ),
              _DetailRow(
                label: '${product.category} average',
                value: _categoryAverageRating > 0
                    ? _categoryAverageRating.toStringAsFixed(1)
                    : '-',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ------------------------ related products ------------------------
        if (_related.isNotEmpty) ...[
          ShopSectionTitle(
            'More in ${product.fandom.isEmpty ? product.category : product.fandom}',
            subtitle: 'You may also like',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 276,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _related.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final related = _related[index];

                return SizedBox(
                  width: 168,
                  child: ProductGridCard(
                    product: related,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(productId: related.id),
                      ),
                    ),
                    onWishlist: () async {
                      final provider = context.read<ShopProvider>();
                      final state = await provider.toggleWishlist(related);

                      if (!mounted || state == null) return;

                      setState(() {
                        _related = _related
                            .map(
                              (item) => item.id == related.id
                                  ? item.copyWith(isWishlisted: state)
                                  : item,
                            )
                            .toList();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // --------------------------- guarantee ---------------------------
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
                Icons.info_outline_rounded,
                size: 15,
                color: ShopTheme.accent,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Checkout in Fandom Verse is a simulation for the project demo - '
                  'no real payment is taken and nothing is shipped.',
                  style: ShopTheme.label(size: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // sticky bottom bar: total + add to cart
  // ------------------------------------------------------------------
  Widget _buildBottomBar(Product product) {
    final total = product.price * _quantity;

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
                Text(
                  _quantity > 1 ? '$_quantity x total' : 'Price',
                  style: ShopTheme.label(size: 11),
                ),
                Text(
                  ShopTheme.formatPrice(total, currency: product.currency),
                  style: ShopTheme.price(size: 20),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ShopPrimaryButton(
                label: 'Add to Cart',
                icon: Icons.add_shopping_cart_rounded,
                loading: _adding,
                onPressed: product.inStock ? _addToCart : null,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Specification row
// ---------------------------------------------------------------------------
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(label, style: ShopTheme.label(size: 12)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
