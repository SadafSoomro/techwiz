import 'package:flutter_test/flutter_test.dart';

class TestItem {
  final int id;
  String name;
  String category;
  double price;

  TestItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });

  TestItem copyWith({
    String? name,
    String? category,
    double? price,
  }) {
    return TestItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
    );
  }
}

class TestItemStore {
  final List<TestItem> _items = [];

  List<TestItem> get items => List.unmodifiable(_items);

  // CREATE (Add)
  void add(TestItem item) {
    _items.add(item);
  }

  // READ / SEARCH
  List<TestItem> search(String query) {
    if (query.trim().isEmpty) return items;
    final q = query.toLowerCase();
    return _items.where((i) => i.name.toLowerCase().contains(q) || i.category.toLowerCase().contains(q)).toList();
  }

  // UPDATE
  bool update(int id, {String? name, String? category, double? price}) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return false;
    _items[index] = _items[index].copyWith(name: name, category: category, price: price);
    return true;
  }

  // DELETE
  bool delete(int id) {
    final before = _items.length;
    _items.removeWhere((i) => i.id == id);
    return _items.length < before;
  }
}

void main() {
  group('Full CRUD Operation Suite (Search, Add, Update, Delete)', () {
    late TestItemStore store;

    setUp(() {
      store = TestItemStore();
      store.add(TestItem(id: 1, name: 'Anime Hoodie', category: 'Apparel', price: 45.0));
      store.add(TestItem(id: 2, name: 'Luffy Gear 5 Figure', category: 'Figures', price: 65.0));
      store.add(TestItem(id: 3, name: 'Gojo Keyring', category: 'Accessories', price: 12.0));
    });

    test('READ: initial items loaded correctly', () {
      expect(store.items.length, 3);
    });

    test('SEARCH: search by keyword works across fields', () {
      final results1 = store.search('figure');
      expect(results1.length, 1);
      expect(results1.first.name, 'Luffy Gear 5 Figure');

      final results2 = store.search('apparel');
      expect(results2.length, 1);
      expect(results2.first.id, 1);

      final emptySearch = store.search('');
      expect(emptySearch.length, 3);

      final noMatch = store.search('nonexistent product');
      expect(noMatch.isEmpty, true);
    });

    test('CREATE: adds new item to the store', () {
      final newItem = TestItem(id: 4, name: 'Zoro Katana Replica', category: 'Collectibles', price: 120.0);
      store.add(newItem);

      expect(store.items.length, 4);
      final found = store.search('Katana');
      expect(found.length, 1);
      expect(found.first.price, 120.0);
    });

    test('UPDATE: updates existing item properties successfully', () {
      final updated = store.update(2, name: 'Luffy Gear 5 Premium Figure', price: 75.0);
      expect(updated, true);

      final item = store.items.firstWhere((i) => i.id == 2);
      expect(item.name, 'Luffy Gear 5 Premium Figure');
      expect(item.price, 75.0);
      expect(item.category, 'Figures'); // unchanged
    });

    test('UPDATE: returns false for non-existent item', () {
      final updated = store.update(999, name: 'Ghost Item');
      expect(updated, false);
    });

    test('DELETE: removes item by id', () {
      final deleted = store.delete(3);
      expect(deleted, true);
      expect(store.items.length, 2);
      expect(store.items.any((i) => i.id == 3), false);
    });

    test('DELETE: returns false for non-existent item id', () {
      final deleted = store.delete(999);
      expect(deleted, false);
      expect(store.items.length, 3);
    });
  });
}
