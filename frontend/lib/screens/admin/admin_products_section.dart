import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Member 6 - Manage Products (merchandise catalogue).
class AdminProductsSection extends StatefulWidget {
  const AdminProductsSection({super.key});

  @override
  State<AdminProductsSection> createState() => _AdminProductsSectionState();
}

class _AdminProductsSectionState extends State<AdminProductsSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _products = [];
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

    final response = await AdminService.products(
      search: _searchController.text.trim(),
      status: _status,
      page: page,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _products = (response['products'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _counts = Map<String, dynamic>.from(response['counts'] ?? {});
        _pagination = Map<String, dynamic>.from(response['pagination'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (response['message'] ?? 'Could not load products.').toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? product}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (saved == true) _load(page: _page);
  }

  int get _page => (_pagination['page'] as num?)?.toInt() ?? 1;
  int get _pages => (_pagination['pages'] as num?)?.toInt() ?? 1;
  int get _total => (_pagination['total'] as num?)?.toInt() ?? 0;

  Future<void> _delete(Map<String, dynamic> product) async {
    final confirmed = await adminConfirm(
      context,
      title: 'Delete product?',
      message:
          '"${product['name']}" will be removed from the store, together '
          'with any wishlist or cart entries for it.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final response = await AdminService.deleteProduct(_id(product));
    if (!mounted) return;

    adminToast(
      context,
      (response['message'] ?? 'Deleted').toString(),
      error: response['success'] != true,
    );
    _load(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AdminTheme.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Manage Products',
            subtitle:
                '${AdminTheme.compact(_total)} matching of '
                '${AdminTheme.compact(_num(_counts['all']))} catalogue items',
            icon: Icons.storefront_rounded,
            action: AdminPrimaryButton(
              label: 'Add Product',
              icon: Icons.add_rounded,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminPill(
                label: '${_num(_counts['active'])} active',
                color: AdminTheme.green,
                icon: Icons.check_circle_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['draft'])} draft',
                color: AdminTheme.amber,
                icon: Icons.edit_note_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['lowStock'])} low stock',
                color: AdminTheme.amber,
                icon: Icons.inventory_2_rounded,
              ),
              AdminPill(
                label: '${_num(_counts['outOfStock'])} out of stock',
                color: AdminTheme.red,
                icon: Icons.remove_shopping_cart_rounded,
              ),
              AdminPill(
                label:
                    '${AdminTheme.money(_num(_counts['inventoryValue']))} inventory',
                color: AdminTheme.cyan,
                icon: Icons.savings_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSearchField(
            controller: _searchController,
            hint: 'Search products by name, category, fandom or SKU...',
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: 12),
          AdminFilterChips(
            options: const {
              '': 'All status',
              'active': 'Active',
              'draft': 'Draft',
            },
            selected: _status,
            onSelected: (value) {
              setState(() => _status = value);
              _load();
            },
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildList()),
          if (!_loading && _error == null)
            AdminPager(
              page: _page,
              pages: _pages,
              total: _total,
              onPage: (page) => _load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const AdminLoader(label: 'Loading products...');
    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _load);
    }
    if (_products.isEmpty) {
      return const AdminEmptyState(
        message: 'No products match these filters.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return AdminPanel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _products.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AdminTheme.border,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          final stock = _num(product['stock']);
          final status = (product['status'] ?? 'active').toString();
          final discount = _num(product['discount_percent']);

          return AdminListRow(
            title: (product['name'] ?? 'Untitled').toString(),
            subtitle:
                '${product['sku'] ?? '-'}  -  '
                '${(product['category'] ?? '-')}'
                '${product['fandom'] != null ? '  -  ${product['fandom']}' : ''}',
            onTap: () => _openForm(product: product),
            leading: AdminImageThumbnail(
              imageUrl: (product['image_url'] ?? '').toString(),
              fallbackIcon: Icons.shopping_bag_rounded,
              fallbackColor: AdminTheme.amber,
              size: 42,
            ),
            pills: [
              AdminPill(label: status, color: AdminTheme.forStatus(status)),
              AdminPill(
                label: stock <= 0 ? 'out of stock' : '$stock in stock',
                color: stock <= 0
                    ? AdminTheme.red
                    : stock <= 5
                    ? AdminTheme.amber
                    : AdminTheme.green,
              ),
              if (discount > 0)
                AdminPill(
                  label: '-${discount.round()}%',
                  color: AdminTheme.pink,
                ),
              if (_toBool(product['is_featured']))
                AdminPill(
                  label: 'featured',
                  color: AdminTheme.violet,
                  icon: Icons.star_rounded,
                ),
            ],
            trailing: AdminMiniStat(
              label: '${AdminTheme.compact(_num(product['sold_count']))} sold',
              value: AdminTheme.money(
                _num(product['price']),
                currency: (product['currency'] ?? 'PKR').toString(),
              ),
              color: AdminTheme.green,
              alignEnd: true,
            ),
            menu: PopupMenuButton<String>(
              color: AdminTheme.surfaceAlt,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AdminTheme.textMuted,
              ),
              onSelected: (value) {
                if (value == 'edit') _openForm(product: product);
                if (value == 'delete') _delete(product);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded, size: 17),
                    title: Text('Edit product', style: TextStyle(fontSize: 13)),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: AdminTheme.red,
                    ),
                    title: Text(
                      'Delete product',
                      style: TextStyle(fontSize: 13, color: AdminTheme.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static int _id(Map<String, dynamic> row) => (row['id'] as num?)?.toInt() ?? 0;

  static num _num(dynamic value) {
    if (value is num) return value;
    if (value == null) return 0;
    return num.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }
}

/* =========================================================================
 * add / edit product
 * ========================================================================= */

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Map<String, dynamic>? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _fandom;
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _oldPrice;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late final TextEditingController _description;

  String _status = 'active';
  bool _featured = false;
  bool _digital = false;
  bool _busy = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product ?? {};
    _name = TextEditingController(text: (p['name'] ?? '').toString());
    _category = TextEditingController(
      text: (p['category'] ?? 'Figures').toString(),
    );
    _fandom = TextEditingController(text: (p['fandom'] ?? '').toString());
    _brand = TextEditingController(text: (p['brand'] ?? '').toString());
    _price = TextEditingController(text: (p['price'] ?? '0').toString());
    _oldPrice = TextEditingController(text: (p['old_price'] ?? '').toString());
    _stock = TextEditingController(text: (p['stock'] ?? '0').toString());
    _imageUrl = TextEditingController(text: (p['image_url'] ?? '').toString());
    _imageUrl.addListener(() => setState(() {}));
    _description = TextEditingController();
    _status = (p['status'] ?? 'active').toString();
    _featured = _toBool(p['is_featured']);
    _digital = _toBool(p['is_digital']);
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _fandom.dispose();
    _brand.dispose();
    _price.dispose();
    _oldPrice.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'category': _category.text.trim(),
      'fandom': _fandom.text.trim(),
      'brand': _brand.text.trim(),
      'price': num.tryParse(_price.text.trim()) ?? 0,
      'old_price': num.tryParse(_oldPrice.text.trim()) ?? 0,
      'stock': num.tryParse(_stock.text.trim()) ?? 0,
      'image_url': _imageUrl.text.trim(),
      'status': _status,
      'is_featured': _featured,
      'is_digital': _digital,
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
    };

    final id = (widget.product?['id'] as num?)?.toInt();
    final response = _isEdit && id != null
        ? await AdminService.updateProduct(id, body)
        : await AdminService.createProduct(body);

    if (!mounted) return;
    setState(() => _busy = false);

    if (response['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    adminToast(
      context,
      (response['message'] ?? 'Could not save the product.').toString(),
      error: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit Product' : 'Add New Product',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _category,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fandom,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Fandom'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Price'),
                        validator: (v) {
                          final parsed = num.tryParse((v ?? '').trim());
                          if (parsed == null) return 'Enter a number';
                          if (parsed < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _oldPrice,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Old price',
                          helperText: 'Enables a discount badge',
                          helperStyle: TextStyle(
                            color: AdminTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Stock'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _brand,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Brand'),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AdminImageThumbnail(
                      imageUrl: _imageUrl.text.trim(),
                      fallbackIcon: Icons.shopping_bag_rounded,
                      fallbackColor: AdminTheme.amber,
                      size: 52,
                      radius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrl,
                        style: TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Image URL or Asset Path',
                          prefixIcon: Icon(Icons.image_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  dropdownColor: AdminTheme.surfaceAlt,
                  style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12.5),
                  decoration: const InputDecoration(
                    labelText: 'Choose Bundled App Product Image (Optional)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Custom / manual path')),
                    DropdownMenuItem(value: 'assets/images/products/luffy_gear5_figure.jpg', child: Text('Luffy Gear 5 Figure')),
                    DropdownMenuItem(value: 'assets/images/products/naruto_sage_figure.jpg', child: Text('Naruto Sage Mode Figure')),
                    DropdownMenuItem(value: 'assets/images/products/tanjiro_kamado_figure.jpg', child: Text('Tanjiro Kamado Figure')),
                    DropdownMenuItem(value: 'assets/images/products/gojo_satoru_figure.jpg', child: Text('Gojo Satoru Figure')),
                    DropdownMenuItem(value: 'assets/images/products/goku_ultra_instinct_figure.jpg', child: Text('Goku Ultra Instinct Figure')),
                    DropdownMenuItem(value: 'assets/images/products/zoro_three_sword_figure.jpg', child: Text('Roronoa Zoro Figure')),
                    DropdownMenuItem(value: 'assets/images/products/mikasa_ackerman_figure.jpg', child: Text('Mikasa Ackerman Figure')),
                    DropdownMenuItem(value: 'assets/images/products/nezuko_kamado_figure.jpg', child: Text('Nezuko Kamado Figure')),
                    DropdownMenuItem(value: 'assets/images/products/sasuke_rinnegan_figure.jpg', child: Text('Sasuke Rinnegan Figure')),
                    DropdownMenuItem(value: 'assets/images/products/straw_hat_crew_tee.jpg', child: Text('Straw Hat Crew Tee')),
                    DropdownMenuItem(value: 'assets/images/products/konoha_leaf_tee.jpg', child: Text('Konoha Leaf Village Tee')),
                    DropdownMenuItem(value: 'assets/images/products/demon_slayer_haori_tee.jpg', child: Text('Demon Slayer Haori Tee')),
                    DropdownMenuItem(value: 'assets/images/products/cursed_energy_tee.jpg', child: Text('Cursed Energy Tee')),
                    DropdownMenuItem(value: 'assets/images/products/survey_corps_tee.jpg', child: Text('Survey Corps Tee')),
                    DropdownMenuItem(value: 'assets/images/products/kpop_lightstick_tee.jpg', child: Text('K-Pop Lightstick Tee')),
                    DropdownMenuItem(value: 'assets/images/products/one_piece_collector_box.jpg', child: Text('One Piece Collector Box')),
                    DropdownMenuItem(value: 'assets/images/products/naruto_legacy_box.jpg', child: Text('Naruto Legacy Box Set')),
                    DropdownMenuItem(value: 'assets/images/products/demon_slayer_trilogy_box.jpg', child: Text('Demon Slayer Trilogy Box')),
                    DropdownMenuItem(value: 'assets/images/products/shonen_starter_bundle.jpg', child: Text('Shonen Starter Bundle')),
                    DropdownMenuItem(value: 'assets/images/products/ghibli_art_collection.jpg', child: Text('Studio Ghibli Art Collection')),
                    DropdownMenuItem(value: 'assets/images/products/akatsuki_cloud_ring.jpg', child: Text('Akatsuki Cloud Ring')),
                    DropdownMenuItem(value: 'assets/images/products/anime_enamel_pin_set.jpg', child: Text('Anime Enamel Pin Set')),
                    DropdownMenuItem(value: 'assets/images/products/straw_hat_keychain.jpg', child: Text('Straw Hat Keychain')),
                    DropdownMenuItem(value: 'assets/images/products/gaming_headset_covers.jpg', child: Text('Gaming Headset Covers')),
                    DropdownMenuItem(value: 'assets/images/products/cosplay_wig_care_kit.jpg', child: Text('Cosplay Wig Care Kit')),
                    DropdownMenuItem(value: 'assets/images/products/anime_4k_wallpaper_pack.jpg', child: Text('Anime 4K Wallpaper Pack')),
                    DropdownMenuItem(value: 'assets/images/products/manga_lettering_font_bundle.jpg', child: Text('Manga Lettering Font Bundle')),
                    DropdownMenuItem(value: 'assets/images/products/fandom_sfx_sound_pack.jpg', child: Text('Fandom SFX Sound Pack')),
                    DropdownMenuItem(value: 'assets/images/products/cosplay_pose_reference_pack.jpg', child: Text('Cosplay Pose Reference Pack')),
                  ],
                  onChanged: (val) {
                    if (val != null && val.isNotEmpty) {
                      setState(() => _imageUrl.text = val);
                    }
                  },
                ),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: AdminTheme.surfaceAlt,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'active'),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  style: TextStyle(color: AdminTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: _isEdit
                        ? 'Description (blank keeps the current text)'
                        : 'Description',
                  ),
                ),
                SwitchListTile(
                  value: _featured,
                  onChanged: (value) => setState(() => _featured = value),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminTheme.violet,
                  title: Text(
                    'Featured product',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: _digital,
                  onChanged: (value) => setState(() => _digital = value),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminTheme.cyan,
                  title: Text(
                    'Digital download',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    'Digital items never go out of stock.',
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.textSecondary,
                          side: BorderSide(color: AdminTheme.border),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminPrimaryButton(
                        label: _isEdit ? 'Save Changes' : 'Create Product',
                        icon: Icons.save_rounded,
                        loading: _busy,
                        expand: true,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }
}
