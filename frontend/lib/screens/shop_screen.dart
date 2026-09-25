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
import 'ai_helper_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'product_details_screen.dart';
import 'wishlist_screen.dart';

/// MEMBER 5 - Merchandise Store
/// Shop Home: hero banner, quick access to Wishlist / Cart / Orders / AI,
/// category + fandom filters, price sorting, the deals carousel and the
/// full product grid.
class ShopScreen extends StatefulWidget {
  final bool embedded;

  const ShopScreen({super.key, this.embedded = false});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, String>> _sortOptions = [
    {'key': 'featured', 'label': 'Featured'},
    {'key': 'price_low', 'label': 'Price ↑'},
    {'key': 'price_high', 'label': 'Price ↓'},
    {'key': 'discount', 'label': 'Biggest deal'},
    {'key': 'rating', 'label': 'Top rated'},
    {'key': 'popular', 'label': 'Best selling'},
    {'key': 'newest', 'label': 'Newest'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ShopProvider>();
      provider.loadOverview();
      provider.loadFilters();
      provider.loadProducts();
      provider.loadPersonal();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<ShopProvider>();
    await provider.loadOverview(silent: true);
    await provider.loadProducts(silent: true);
    await provider.loadPersonal(silent: true);
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openProduct(int productId) {
    _open(ProductDetailsScreen(productId: productId));
  }

  Future<void> _addToCart(Product product) async {
    final provider = context.read<ShopProvider>();
    final message = await provider.addToCart(product);

    if (!mounted) return;

    if (message == null) {
      _snack(provider.errorMessage ?? 'Could not add the item', isError: true);
      return;
    }
    _snack(
      message,
      action: 'View cart',
      onAction: () => _open(const CartScreen()),
    );
  }

  Future<void> _toggleWishlist(Product product) async {
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

    _snack(
      result
          ? 'Added to wishlist - we will watch the price for you'
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

    return ShopScaffold(
      title: 'Shop',
      subtitle: 'Official fandom merchandise & exclusives',
      showBackButton: !widget.embedded,
      actions: [
        ShopHeaderAction(
          icon: Icons.auto_awesome_rounded,
          tooltip: 'AI Fan Helper',
          onTap: () => _open(const AiHelperScreen()),
        ),
        ShopHeaderAction(
          icon: Icons.favorite_rounded,
          tooltip: 'Wishlist',
          badgeCount: provider.wishlistCount,
          onTap: () => _open(const WishlistScreen()),
        ),
        ShopHeaderAction(
          icon: Icons.shopping_bag_rounded,
          tooltip: 'Cart',
          badgeCount: provider.cartQuantity,
          onTap: () => _open(const CartScreen()),
        ),
      ],
      child: RefreshIndicator(
        color: ShopTheme.primary,
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            // ------------------------- hero banner -------------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _ShopHeroBanner(),
            ),
            const SizedBox(height: 16),

            // ------------------------ quick actions ------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _QuickTile(
                    icon: Icons.favorite_rounded,
                    label: 'Wishlist',
                    color: ShopTheme.secondary,
                    badge: provider.wishlistCount,
                    onTap: () => _open(const WishlistScreen()),
                  ),
                  const SizedBox(width: 10),
                  _QuickTile(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Cart',
                    color: ShopTheme.primary,
                    badge: provider.cartQuantity,
                    onTap: () => _open(const CartScreen()),
                  ),
                  const SizedBox(width: 10),
                  _QuickTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Orders',
                    color: ShopTheme.green,
                    badge: provider.ordersCount,
                    onTap: () => _open(const OrdersScreen()),
                  ),
                  const SizedBox(width: 10),
                  _QuickTile(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Helper',
                    color: ShopTheme.accent,
                    onTap: () => _open(const AiHelperScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // --------------------------- stats ---------------------------
            _buildStats(provider),
            const SizedBox(height: 22),

            // ------------------------- search bar -------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => provider.search(value.trim()),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search figures, tees, box sets...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: provider.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            provider.search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: ShopTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: ShopTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ------------------------ categories ------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShopSectionTitle(
                'Shop by category',
                subtitle:
                    '${provider.stats.totalProducts} products - '
                    '${provider.stats.totalDeals} on offer',
              ),
            ),
            const SizedBox(height: 10),
            ShopChipRow(
              children: [
                ShopFilterChip(
                  label: 'All',
                  selected: provider.category == 'All',
                  icon: Icons.grid_view_rounded,
                  onTap: () => provider.selectCategory('All'),
                ),
                ...provider.categories.map(
                  (category) => ShopFilterChip(
                    label: category.name,
                    selected: provider.category == category.name,
                    icon: ShopTheme.iconFor(category.icon),
                    accentColor: ShopTheme.fromHex(
                      category.color,
                      fallback: ShopTheme.categoryColor(category.name),
                    ),
                    count: category.productCount,
                    onTap: () => provider.selectCategory(category.name),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---------------------- sort + toggles ----------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sortOptions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final option = _sortOptions[index];
                          return Center(
                            child: ShopFilterChip(
                              label: option['label']!,
                              selected: provider.sort == option['key'],
                              icon: Icons.swap_vert_rounded,
                              accentColor: ShopTheme.accent,
                              onTap: () => provider.selectSort(option['key']!),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ShopFilterChip(
                    label: 'In stock only',
                    selected: provider.inStockOnly,
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: ShopTheme.green,
                    onTap: provider.toggleInStockOnly,
                  ),
                  const SizedBox(width: 8),
                  ShopFilterChip(
                    label: 'On sale',
                    selected: provider.discountedOnly,
                    icon: Icons.local_offer_rounded,
                    accentColor: ShopTheme.orange,
                    onTap: provider.toggleDiscountedOnly,
                  ),
                  const Spacer(),
                  if (provider.hasActiveFilters)
                    TextButton(
                      onPressed: provider.resetFilters,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reset',
                        style: GoogleFonts.inter(
                          color: ShopTheme.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ------------------ merchandising rows (unfiltered) ------------------
            if (!provider.hasActiveFilters) ...[
              if (provider.deals.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ShopSectionTitle(
                    'Deals of the week',
                    subtitle: 'Limited-time price drops',
                    trailing: ShopSeeAll(
                      label: 'All deals',
                      color: ShopTheme.orange,
                      onTap: () {
                        provider.toggleDiscountedOnly();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AutoScrollRow(
                  height: 196,
                  children: [
                    ...provider.deals.map(
                      (product) => ProductMiniCard(
                        product: product,
                        onTap: () => _openProduct(product.id),
                      ),
                    ),
                    // duplicate so the loop never looks empty at the seam
                    ...provider.deals.map(
                      (product) => ProductMiniCard(
                        product: product,
                        onTap: () => _openProduct(product.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              if (provider.featured.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const ShopSectionTitle(
                    'Fandom exclusives',
                    subtitle: 'Hand-picked collector pieces',
                  ),
                ),
                const SizedBox(height: 12),
                _buildAutoGrid(provider.featured),
                const SizedBox(height: 24),
              ],
            ],

            // ----------------------- main catalogue -----------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShopSectionTitle(
                provider.hasActiveFilters
                    ? '${provider.resultCount} result${provider.resultCount == 1 ? '' : 's'}'
                    : 'All merchandise',
                subtitle: provider.query.isNotEmpty
                    ? 'Searching for "${provider.query}"'
                    : 'Every product in the store',
              ),
            ),
            const SizedBox(height: 12),

            if (provider.loadingProducts && provider.products.isEmpty)
              _buildSkeletonGrid()
            else if (provider.products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  decoration: ShopTheme.card(),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products match those filters',
                        style: ShopTheme.title(size: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different category or search word',
                        style: ShopTheme.label(size: 12),
                      ),
                      const SizedBox(height: 16),
                      ShopOutlineButton(
                        label: 'Reset filters',
                        icon: Icons.refresh_rounded,
                        onPressed: provider.resetFilters,
                        expanded: false,
                        height: 44,
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildGrid(provider.products),

            // ------------------- new arrivals / best sellers -------------------
            if (!provider.hasActiveFilters) ...[
              const SizedBox(height: 26),
              if (provider.newArrivals.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const ShopSectionTitle(
                    'New arrivals',
                    subtitle: 'Fresh in the store',
                  ),
                ),
                const SizedBox(height: 12),
                _buildAutoGrid(provider.newArrivals),
                const SizedBox(height: 24),
              ],
              if (provider.bestSellers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const ShopSectionTitle(
                    'Best sellers',
                    subtitle: 'Most loved by the community',
                  ),
                ),
                const SizedBox(height: 12),
                _buildAutoGrid(provider.bestSellers),
                const SizedBox(height: 20),
              ],
            ],

            // --------------------------- AI banner ---------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AiHelperBanner(
                onTap: () => _open(const AiHelperScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // builders
  // ------------------------------------------------------------------

  Widget _buildStats(ShopProvider provider) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SizedBox(
            width: 132,
            child: ShopStatTile(
              label: 'Products',
              value: '${provider.stats.totalProducts}',
              counterValue: provider.stats.totalProducts,
              icon: Icons.inventory_2_rounded,
              color: ShopTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: ShopStatTile(
              label: 'On offer',
              value: '${provider.stats.totalDeals}',
              counterValue: provider.stats.totalDeals,
              icon: Icons.local_offer_rounded,
              color: ShopTheme.orange,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: ShopStatTile(
              label: 'In my cart',
              value: '${provider.cartQuantity}',
              counterValue: provider.cartQuantity,
              icon: Icons.shopping_bag_rounded,
              color: ShopTheme.green,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: ShopStatTile(
              label: 'Wishlisted',
              value: '${provider.wishlistCount}',
              counterValue: provider.wishlistCount,
              icon: Icons.favorite_rounded,
              color: ShopTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.60,
        ),
        itemBuilder: (context, index) {
          final product = products[index];

          return BounceIn(
            delay: Duration(milliseconds: 40 * (index % 6)),
            child: ProductGridCard(
              product: product,
              onTap: () => _openProduct(product.id),
              onWishlist: () => _toggleWishlist(product),
              onAddToCart: () => _addToCart(product),
              ribbon: product.isFeatured ? 'EXCLUSIVE' : null,
            ),
          );
        },
      ),
    );
  }

  /// A horizontally scrolling row of grid cards (used for the merchandising
  /// shelves so they animate like the deals carousel).
  Widget _buildAutoGrid(List<Product> products) {
    return SizedBox(
      height: 276,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];

          return SizedBox(
            width: 168,
            child: BounceIn(
              delay: Duration(milliseconds: 50 * (index % 5)),
              child: ProductGridCard(
                product: product,
                onTap: () => _openProduct(product.id),
                onWishlist: () => _toggleWishlist(product),
                onAddToCart: () => _addToCart(product),
                ribbon: product.isFeatured ? 'EXCLUSIVE' : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.60,
        ),
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero banner - the "Hands Up! Fandom Exclusives" card from the design board
// ---------------------------------------------------------------------------
class _ShopHeroBanner extends StatelessWidget {
  const _ShopHeroBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient base keeps the banner alive even if the
            // bundled artwork is missing.
            const AnimatedGradientBox(
              colors: [
                ShopTheme.primary,
                ShopTheme.secondary,
                Color(0xFF1E1B4B),
              ],
            ),

            // The bundled hero artwork, drifting slowly.
            FloatingBox(
              amplitude: 6,
              period: const Duration(milliseconds: 5200),
              child: Image.asset(
                ShopTheme.heroBanner,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),

            // Legibility scrim.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Copy + CTA.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      'FANDOM EXCLUSIVES',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hands Up!',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Figures, tees, box sets & digital art\nstraight from the fandom vault.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Floating discount sticker.
            Positioned(
              right: 14,
              top: 14,
              child: FloatingBox(
                amplitude: 5,
                horizontalAmplitude: 3,
                phase: 1.2,
                period: const Duration(milliseconds: 2900),
                child: PulseGlow(
                  color: ShopTheme.orange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: ShopTheme.dealGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'UP TO',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          '40% OFF',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick access tile
// ---------------------------------------------------------------------------
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleOnTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: ShopTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.26)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ShopTheme.label(size: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Fan Helper promo banner
// ---------------------------------------------------------------------------
class _AiHelperBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AiHelperBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ShopTheme.aiGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: ShopTheme.accent.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            FloatingBox(
              amplitude: 4,
              period: const Duration(milliseconds: 2800),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Fan Helper',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ask about lore, characters, recommendations or a price',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
