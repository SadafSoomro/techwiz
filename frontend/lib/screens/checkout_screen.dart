import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/shop_models.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_animated.dart';
import '../widgets/shop_scaffold.dart';
import '../widgets/shop_widgets.dart';
import 'order_success_screen.dart';

/// MEMBER 5 - Merchandise Store
/// Checkout (simulated): the order summary / bill from the design board plus
/// the delivery form. Confirming places the simulated order - the SRS keeps
/// real payment and delivery out of scope, so nothing is charged.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentMethod = 'Cash on Delivery (simulated)';
  bool _placing = false;

  static const List<String> _paymentMethods = [
    'Cash on Delivery (simulated)',
    'Card (simulated)',
    'Wallet (simulated)',
  ];

  static const List<String> _cities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
  ];

  /// A postal address is only required when the cart has a physical item.
  bool get _needsAddress {
    final cart = context.read<ShopProvider>().cart;
    return cart.hasPhysical || cart.items.isEmpty;
  }

  @override
  void initState() {
    super.initState();

    // Prefill from the signed-in account so the demo is one tap quicker.
    final user = context.read<AuthProvider>().user;
    _nameController.text = (user?['name'] ?? '').toString();
    _phoneController.text = (user?['phone'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() => _placing = true);

    final provider = context.read<ShopProvider>();
    final result = await provider.checkout(
      shippingName: _nameController.text.trim(),
      shippingPhone: _phoneController.text.trim(),
      shippingCity: _cityController.text.trim(),
      shippingAddress: _addressController.text.trim(),
      note: _noteController.text.trim(),
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;
    setState(() => _placing = false);

    if (result.order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: ShopTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Replace so the user cannot go "back" into a checkout that has no cart.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(order: result.order!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final cart = provider.cart;

    if (cart.isEmpty) {
      return ShopScaffold(
        title: 'Checkout',
        child: ShopEmptyState(
          title: 'Nothing to check out',
          message: 'Your cart is empty, so there is no bill to review yet.',
          icon: Icons.shopping_bag_outlined,
          actionLabel: 'Back to the shop',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    return ShopScaffold(
      title: 'Checkout',
      subtitle: 'Simulated - no real payment is taken',
      bottomBar: _buildBottomBar(cart),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
          children: [
            // ------------------------- order summary -------------------------
            BounceIn(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ShopTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: ShopTheme.primary.withValues(alpha: 0.28),
                  ),
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
                        const Spacer(),
                        Text(
                          '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                          style: ShopTheme.label(size: 11.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ---------------- line items ----------------
                    ...cart.items.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ProductImage(
                              imageUrl: line.imageUrl,
                              category: line.category,
                              width: 42,
                              height: 42,
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
                                    '${ShopTheme.formatPrice(line.price, currency: line.currency)}',
                                    style: ShopTheme.label(size: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              ShopTheme.formatPrice(
                                line.lineTotal,
                                currency: line.currency,
                              ),
                              style: ShopTheme.price(size: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 14,
                    ),

                    // ------------------- bill -------------------
                    ShopBillRow(
                      label: 'Subtotal',
                      value: ShopTheme.formatPrice(
                        cart.subtotal,
                        currency: cart.currency,
                      ),
                    ),
                    if (cart.discount > 0)
                      ShopBillRow(
                        label:
                            'Discount ${cart.promoCode != null ? '(${cart.promoCode})' : ''}',
                        value:
                            '- ${ShopTheme.formatPrice(cart.discount, currency: cart.currency)}',
                        valueColor: ShopTheme.green,
                      ),
                    ShopBillRow(
                      label: 'Shipping',
                      value: cart.shippingFee == 0
                          ? 'Free'
                          : ShopTheme.formatPrice(
                              cart.shippingFee,
                              currency: cart.currency,
                            ),
                      valueColor: cart.shippingFee == 0
                          ? ShopTheme.green
                          : null,
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 16,
                    ),
                    ShopBillRow(
                      label: 'Total payable',
                      value: ShopTheme.formatPrice(
                        cart.total,
                        currency: cart.currency,
                      ),
                      emphasised: true,
                      valueColor: ShopTheme.gold,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ----------------------- delivery details -----------------------
            Text(
              _needsAddress ? 'Delivery details' : 'Digital order',
              style: ShopTheme.title(size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _needsAddress ? 'Where should this order be delivered?' : 'This order only contains digital items, so no address is needed.',
              style: ShopTheme.label(size: 11.5),
            ),
            const SizedBox(height: 12),

            if (_needsAddress) ...[
              _field(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Please enter the recipient name'
                    : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneController,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _cityDropdown(),
              const SizedBox(height: 12),
              _field(
                controller: _addressController,
                label: 'Delivery address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (value) => (value ?? '').trim().length < 8
                    ? 'Please enter a complete address'
                    : null,
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ShopTheme.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: ShopTheme.accent.withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_download_rounded,
                      size: 18,
                      color: ShopTheme.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your download links appear on the order confirmation and '
                        'in your Orders list.',
                        style: ShopTheme.label(size: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ----------------------- payment method -----------------------
            Text('Payment method', style: ShopTheme.title(size: 16)),
            const SizedBox(height: 4),
            Text(
              'Every option is simulated for the project demo.',
              style: ShopTheme.label(size: 11.5),
            ),
            const SizedBox(height: 10),
            ..._paymentMethods.map(
              (method) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentOption(
                  label: method,
                  selected: _paymentMethod == method,
                  icon: method.startsWith('Cash')
                      ? Icons.payments_outlined
                      : method.startsWith('Card')
                      ? Icons.credit_card_rounded
                      : Icons.account_balance_wallet_outlined,
                  onTap: () => setState(() => _paymentMethod = method),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --------------------------- note ---------------------------
            Text('Order note (optional)', style: ShopTheme.title(size: 16)),
            const SizedBox(height: 10),
            _field(
              controller: _noteController,
              label: 'Anything we should know?',
              icon: Icons.edit_note_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

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
                    color: ShopTheme.gold,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Confirming places a simulated order so you can review the bill '
                      'in your order history. No payment is processed and nothing is '
                      'shipped - this is excluded from the project scope.',
                      style: ShopTheme.label(size: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildBottomBar(CartSummary cart) {
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
                label: 'Confirm Order',
                icon: Icons.check_circle_outline_rounded,
                height: 48,
                loading: _placing,
                onPressed: _confirmOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: ShopTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopTheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopTheme.red, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopTheme.red, width: 1.8),
        ),
      ),
    );
  }

  Widget _cityDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _cities.contains(_cityController.text)
          ? _cityController.text
          : null,
      dropdownColor: ShopTheme.surfaceLight,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
      icon: const Icon(
        Icons.expand_more_rounded,
        color: AppTheme.textSecondary,
      ),
      decoration: InputDecoration(
        labelText: 'City',
        prefixIcon: const Icon(Icons.location_city_rounded, size: 19),
        filled: true,
        fillColor: ShopTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopTheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopTheme.red, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopTheme.red, width: 1.8),
        ),
      ),
      items: _cities
          .map(
            (city) => DropdownMenuItem(
              value: city,
              child: Text(city, style: GoogleFonts.inter(color: Colors.white)),
            ),
          )
          .toList(),
      validator: (value) =>
          (value ?? '').isEmpty ? 'Please select a city' : null,
      onChanged: (value) => _cityController.text = value ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Payment option radio row
// ---------------------------------------------------------------------------
class _PaymentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? ShopTheme.primary.withValues(alpha: 0.14)
              : ShopTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? ShopTheme.primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? ShopTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? ShopTheme.primary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? ShopTheme.primary
                      : Colors.white.withValues(alpha: 0.22),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
