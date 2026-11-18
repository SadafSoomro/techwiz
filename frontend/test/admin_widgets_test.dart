import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/admin_widgets.dart';

void main() {
  group('Admin Widgets Responsiveness & Overflow Tests', () {
    testWidgets('AdminPill renders without overflow even with long labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80, // Very tight width
              child: AdminPill(
                label: 'Very Long Status Label That Could Overflow',
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AdminPill), findsOneWidget);
    });

    testWidgets('AdminMiniStat renders safely without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60,
              child: AdminMiniStat(
                label: 'Total Booked Capacity',
                value: '999,999 Tickets',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AdminMiniStat), findsOneWidget);
    });

    testWidgets('AdminListRow renders cleanly in compact mobile width (320px)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320, // Very narrow screen (e.g. small mobile)
              child: AdminListRow(
                title: 'One Piece Wano Finale Screening Ultra Fan Edition',
                subtitle: 'Islamabad · 2026-09-27 · Anime · Convention',
                pills: const [
                  AdminPill(label: 'Anime', color: Colors.purple),
                  AdminPill(label: 'Featured', color: Colors.amber),
                  AdminPill(label: 'Convention', color: Colors.blue),
                ],
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    AdminMiniStat(label: 'Price', value: '\$15.00'),
                    SizedBox(width: 8),
                    AdminMiniStat(label: 'Booked', value: '45/100'),
                  ],
                ),
                menu: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify no Flutter layout exception / RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
      expect(find.byType(AdminListRow), findsOneWidget);
      expect(find.text('One Piece Wano Finale Screening Ultra Fan Edition'), findsOneWidget);
    });

    testWidgets('AdminPager renders nicely on compact width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AdminPager(
                page: 1,
                pages: 5,
                total: 120,
                onPage: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AdminPager), findsOneWidget);
    });
  });
}
