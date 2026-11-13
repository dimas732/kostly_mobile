import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kost_ly/models/kos_model.dart';
import 'package:kost_ly/widgets/calculator_widgets.dart';

KosModel makeKos({
  Map<String, int> recurring = const {},
  Map<String, int> electrical = const {},
}) {
  return KosModel.fromFirestore({
    'name': 'Kos Uji',
    'rent_price': 1000000,
    'reccuring_cost': recurring,
    'electrical_cost': electrical,
  }, 'kos-uji');
}

Future<void> showCalculator(WidgetTester tester, KosModel kos) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: KosCostCalculator(kost: kos)),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Tarif tersimpan dijumlahkan dan pilihan pencari memperbarui total',
    (tester) async {
      final kos = makeKos(
        recurring: {'air': 50000, 'wifi': 100000},
        electrical: {'listrik': 150000},
      );
      await showCalculator(tester, kos);
      expect(find.text('Rp 1.300.000'), findsNWidgets(2));
      expect(find.text('Rp 300.000'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cost_wifi')));
      await tester.pump();
      expect(find.text('Rp 1.200.000'), findsNWidgets(2));

      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 bulan').last);
      await tester.pumpAndSettle();
      expect(find.text('Rp 3.600.000'), findsOneWidget);
      expect(find.text('Total 3 bulan'), findsOneWidget);
      expect(kos.reccuringCost['wifi'], 100000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Kos lama tanpa biaya tambahan tetap bisa dihitung', (
    tester,
  ) async {
    await showCalculator(tester, makeKos());
    expect(find.text('Tidak ada biaya tambahan'), findsNWidgets(3));
    expect(find.text('Rp 1.000.000'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
