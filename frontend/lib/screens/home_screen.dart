import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/event_models.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/event_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../theme/shop_theme.dart';
import '../widgets/fandom_logo.dart';
import '../widgets/product_image.dart';
import 'bookmarks_screen.dart';
import 'discussions_screen.dart';
import 'event_calendar_screen.dart';
import 'event_categories_screen.dart';
import 'event_details_screen.dart';
import 'event_map_screen.dart';
import 'events_screen.dart';
import 'ai_helper_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';
import 'wishlist_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'saved_events_screen.dart';
import 'search_screen.dart';
import 'trending_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // MEMBER 3 - Search & Community: warm up the community data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final community = context.read<CommunityProvider>();
      community.refreshUnreadCount();
      community.loadOverview();

      // MEMBER 4 - Events & Maps: warm up the events data.
      final events = context.read<EventProvider>();
      events.loadOverview();
      events.loadEvents();

      // MEMBER 5 - Merchandise Store + AI Fan Helper: warm up the shop data.
      final shop = context.read<ShopProvider>();
      shop.loadOverview();
      shop.loadFilters();
      shop.loadProducts();
      shop.loadPersonal();
      context.read<AiProvider>().initialise(restoreHistory: false);
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout Confirmation',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of FANDOM VERSE?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?['name'] ?? 'Emma';
    final userEmail = user?['email'] ?? 'user@fandomverse.com';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              // Tab 0: Home Dashboard (Screen 5)
              _buildHomeDashboard(userName),

              // Tab 1: Events Section  (MEMBER 4 - Events & Maps)
              const EventsScreen(embedded: true),

              // Tab 2: Shop / Merchandise Section (MEMBER 5 - Merchandise Store)
              const ShopScreen(embedded: true),

              // Tab 3: Bookmarks  (MEMBER 3 - Search & Community)
              const BookmarksScreen(embedded: true),

              // Tab 4: Profile & Account Settings (Screen 18)
              _buildProfileTab(userName, userEmail, authProvider),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.cardColor,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.secondaryColor,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_rounded),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline_rounded),
              label: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard(String userName) {
    final eventProvider = context.watch<EventProvider>();
    final shopProvider = context.watch<ShopProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const FandomLogoWidget(height: 38),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                  ),
                  // Notifications with unread badge (MEMBER 3)
                  Consumer<CommunityProvider>(
                    builder: (context, community, _) => Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                            if (context.mounted) community.refreshUnreadCount();
                          },
                        ),
                        if (community.unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                community.unreadCount > 9
                                    ? '9+'
                                    : '${community.unreadCount}',
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
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Greeting Text
          Text(
            'Hello, $userName! 👋',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Good to see you back!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Search Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.inputFillColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search fandoms, news, events...',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Trending Now Banner Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Now',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Featured Card (One Piece / Anime Featured)
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 180,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'HOT FEATURED',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'One Piece - Wano Arc Finale',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'New episode & latest community updates',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Read More',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Your Fandoms Horizontal Chips
          Text(
            'Your Fandoms',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFandomCategoryChip(
                  'Anime',
                  Icons.auto_awesome_rounded,
                  AppTheme.secondaryColor,
                ),
                _buildFandomCategoryChip(
                  'Gaming',
                  Icons.sports_esports_rounded,
                  Colors.blue,
                ),
                _buildFandomCategoryChip(
                  'Movies',
                  Icons.movie_creation_rounded,
                  Colors.amber,
                ),
                _buildFandomCategoryChip(
                  'Comics',
                  Icons.menu_book_rounded,
                  Colors.orange,
                ),
                _buildFandomCategoryChip(
                  'K-Pop',
                  Icons.music_note_rounded,
                  Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ============================================================
          // MEMBER 3 - Search & Community quick access
          // ============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Community',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiscussionsScreen(),
                    ),
                  );
                },
                child: Text(
                  'All discussions',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCommunityTile(
                'Trending',
                Icons.local_fire_department_rounded,
                AppTheme.secondaryColor,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrendingScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _buildCommunityTile(
                'Deep Dive',
                Icons.auto_awesome_rounded,
                AppTheme.primaryColor,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiscussionsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCommunityTile(
                'Search',
                Icons.search_rounded,
                AppTheme.accentCyan,
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              const SizedBox(width: 12),
              _buildCommunityTile(
                'Bookmarks',
                Icons.bookmark_rounded,
                Colors.amber,
                () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ============================================================
          // MEMBER 4 - Events & Maps quick access
          // ============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events Near You',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    color: EventTheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (eventProvider.nextEvent != null)
            _buildNextEventCard(eventProvider.nextEvent!)
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_busy_rounded, color: EventTheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Loading upcoming events...',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCommunityTile(
                'Map',
                Icons.map_rounded,
                EventTheme.teal,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EventMapScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _buildCommunityTile(
                'Calendar',
                Icons.calendar_month_rounded,
                EventTheme.amber,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EventCalendarScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCommunityTile(
                'Categories',
                Icons.category_rounded,
                EventTheme.primary,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EventCategoriesScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildCommunityTile(
                'Interested',
                Icons.favorite_rounded,
                EventTheme.secondary,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedEventsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ============================================================
          // MEMBER 5 - Merchandise Store + AI Fan Helper quick access
          // ============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fandom Shop',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    color: ShopTheme.secondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildShopHeroCard(shopProvider),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCommunityTile(
                'Wishlist (${shopProvider.wishlistCount})',
                Icons.favorite_rounded,
                ShopTheme.secondary,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _buildCommunityTile(
                'Cart (${shopProvider.cartQuantity})',
                Icons.shopping_bag_rounded,
                ShopTheme.primary,
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCommunityTile(
                'My Orders',
                Icons.receipt_long_rounded,
                ShopTheme.green,
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
              ),
              const SizedBox(width: 12),
              _buildCommunityTile(
                'AI Helper',
                Icons.auto_awesome_rounded,
                ShopTheme.accent,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiHelperScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact shop highlight card for the home dashboard (MEMBER 5).
  Widget _buildShopHeroCard(ShopProvider shop) {
    final deals = shop.deals.take(3).toList();

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(gradient: ShopTheme.dealGradient),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    ShopTheme.dealsBanner,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'DEALS OF THE WEEK',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${shop.stats.totalDeals} offers',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Official merch, fan prices',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.cartQuantity > 0
                          ? '${shop.cartQuantity} item(s) in your cart - checkout whenever you like'
                          : 'Figures, tees, box sets and digital art from the fandom vault',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    if (deals.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ...deals.map(
                            (product) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ProductImage(
                                imageUrl: product.imageUrl,
                                category: product.category,
                                width: 42,
                                height: 42,
                                radius: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                'Shop now',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact "next event" card for the home dashboard (MEMBER 4).
  Widget _buildNextEventCard(EventItem event) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailsScreen(eventId: event.id, event: event),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: EventTheme.featuredGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: EventTheme.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -26,
              child: Icon(
                EventTheme.categoryIcon(event.category),
                size: 120,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    EventTheme.countdown(event.daysUntil).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${event.venue}, ${event.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    Text(
                      EventTheme.prettyDate(event.eventDate),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Small quick-access card used by the community section of the dashboard.
  Widget _buildCommunityTile(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFandomCategoryChip(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(
    String userName,
    String userEmail,
    AuthProvider authProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.buttonGradient,
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.cardColor,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            userEmail,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // User status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.successColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Authenticated via Provider State',
                  style: GoogleFonts.inter(
                    color: AppTheme.successColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings items list
          _buildProfileOptionItem(
            Icons.person_outline_rounded,
            'Edit Profile',
            () {},
          ),
          _buildProfileOptionItem(
            Icons.bookmark_outline_rounded,
            'My Saved Fandoms',
            () {},
          ),
          // MEMBER 5 - Merchandise Store shortcuts
          _buildProfileOptionItem(
            Icons.receipt_long_rounded,
            'Purchase History',
            () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
          ),
          _buildProfileOptionItem(
            Icons.favorite_border_rounded,
            'My Wishlist',
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
          _buildProfileOptionItem(Icons.settings_outlined, 'Settings', () {}),
          const SizedBox(height: 16),

          // Logout Button
          ListTile(
            onTap: _handleLogout,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: AppTheme.errorColor.withOpacity(0.12),
            leading: const Icon(
              Icons.logout_rounded,
              color: AppTheme.errorColor,
            ),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptionItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: AppTheme.cardColor,
        leading: Icon(icon, color: AppTheme.textSecondary),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
