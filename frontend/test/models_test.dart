import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/event_models.dart';
import 'package:frontend/models/shop_models.dart';

void main() {
  group('EventItem Model & Logic Tests', () {
    test('EventItem correctly parses JSON and computes price/status', () {
      final json = {
        'id': 101,
        'title': 'Tokyo Anime Expo 2026',
        'description': 'The largest gathering of anime fans in Asia',
        'city': 'Tokyo',
        'venue': 'Tokyo Big Sight',
        'category': 'Convention',
        'event_date': '2026-10-15',
        'start_time': '10:00',
        'end_time': '18:00',
        'ticket_price': 45.0,
        'capacity': 5000,
        'tickets_sold': 1200,
        'seats_left': 3800,
        'is_featured': 1,
        'image_url': 'assets/images/events/sample.jpg',
      };

      final event = EventItem.fromJson(json);

      expect(event.id, 101);
      expect(event.title, 'Tokyo Anime Expo 2026');
      expect(event.city, 'Tokyo');
      expect(event.ticketPrice, 45.0);
      expect(event.isFree, false);
      expect(event.capacity, 5000);
      expect(event.ticketsSold, 1200);
      expect(event.seatsLeft, 3800);
      expect(event.isFeatured, true);
    });

    test('EventItem free event handling', () {
      final json = {
        'id': 102,
        'title': 'Cosplay Meetup Free',
        'ticket_price': 0,
        'capacity': 100,
        'tickets_sold': 100,
        'seats_left': 0,
      };

      final event = EventItem.fromJson(json);
      expect(event.isFree, true);
      expect(event.seatsLeft, 0);
    });

    test('Search filter logic matches title, city, or category', () {
      final events = [
        const EventItem(
          id: 1,
          title: 'Naruto Night',
          city: 'Karachi',
          category: 'Anime',
          eventDate: '2026-10-01',
          startTime: '18:00',
          ticketPrice: 10.0,
          capacity: 100,
        ),
        const EventItem(
          id: 2,
          title: 'Gaming Championship',
          city: 'Lahore',
          category: 'Gaming',
          eventDate: '2026-10-05',
          startTime: '12:00',
          ticketPrice: 25.0,
          capacity: 200,
        ),
        const EventItem(
          id: 3,
          title: 'Sci-Fi Film Screening',
          city: 'Karachi',
          category: 'Sci-Fi',
          eventDate: '2026-10-10',
          startTime: '20:00',
          ticketPrice: 0.0,
          capacity: 50,
        ),
      ];

      // Search by query "Karachi"
      final karachiEvents = events.where((e) => e.city.toLowerCase().contains('karachi')).toList();
      expect(karachiEvents.length, 2);

      // Search by query "naruto"
      final narutoEvents = events.where((e) => e.title.toLowerCase().contains('naruto')).toList();
      expect(narutoEvents.length, 1);
      expect(narutoEvents.first.id, 1);

      // Filter by free
      final freeEvents = events.where((e) => e.isFree).toList();
      expect(freeEvents.length, 1);
      expect(freeEvents.first.id, 3);
    });
  });

  group('Shop Product & Cart Logic Tests', () {
    test('Product correctly parses and computes discount', () {
      final json = {
        'id': 50,
        'name': 'Goku Super Saiyan Figure',
        'price': 39.99,
        'old_price': 49.99,
        'discount_percent': 20,
        'stock': 15,
        'rating': 4.8,
        'category': 'Figures',
        'fandom': 'Anime',
      };

      final product = Product.fromJson(json);
      expect(product.id, 50);
      expect(product.name, 'Goku Super Saiyan Figure');
      expect(product.price, 39.99);
      expect(product.oldPrice, 49.99);
      expect(product.hasDiscount, true);
      expect(product.stock, 15);
      expect(product.inStock, true);
    });

    test('CartLine calculation and JSON deserialization', () {
      final json = {
        'cart_item_id': 10,
        'product_id': 50,
        'name': 'Demon Slayer Keychain',
        'price': 12.50,
        'stock': 5,
        'quantity': 3,
        'line_total': 37.50,
      };

      final cartLine = CartLine.fromJson(json);

      expect(cartLine.cartItemId, 10);
      expect(cartLine.productId, 50);
      expect(cartLine.name, 'Demon Slayer Keychain');
      expect(cartLine.quantity, 3);
      expect(cartLine.lineTotal, 37.50);
      expect(cartLine.maxQuantity, 5);
    });

    test('CartSummary calculates subtotal, discounts and shipping accurately', () {
      final json = {
        'item_count': 3,
        'subtotal': 90.0,
        'discount': 9.0,
        'discount_label': '10% off',
        'shipping_fee': 0.0,
        'free_shipping': true,
        'total': 81.0,
        'currency': 'USD',
        'items': [
          {
            'cart_item_id': 1,
            'product_id': 1,
            'name': 'T-Shirt',
            'price': 20.0,
            'quantity': 2,
            'line_total': 40.0,
          },
          {
            'cart_item_id': 2,
            'product_id': 2,
            'name': 'Hoodie',
            'price': 50.0,
            'quantity': 1,
            'line_total': 50.0,
          }
        ]
      };

      final summary = CartSummary.fromJson(json);

      expect(summary.itemCount, 3);
      expect(summary.subtotal, 90.0);
      expect(summary.discount, 9.0);
      expect(summary.shippingFee, 0.0);
      expect(summary.freeShipping, true);
      expect(summary.total, 81.0);
      expect(summary.items.length, 2);
      expect(summary.isEmpty, false);
    });
  });
}
