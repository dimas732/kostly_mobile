import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kost_ly/models/electricity_pricing.dart';
import 'package:kost_ly/models/kos_model.dart';
import 'package:kost_ly/widgets/calculator_widgets.dart';
import 'package:kost_ly/widgets/electricity_pricing_editor.dart';

void main() {
  const item = ElectricityItem(name: 'Kipas', monthlyFee: 10000, watts: 50);

  test('Tiga kategori memakai komponen biaya yang sesuai', () {
    const usage = [ElectricityUsage(quantity: 2, hoursPerDay: 8)];
    for (final mode in ElectricityMode.values) {
      final pricing = ElectricityPricing(
        mode: mode,
        fixedMonthly: 150000,
        pricePerKwh: 1000,
        items: [item],
      );
      final result = pricing.estimate(usage);
      expect(result.total, switch (mode) {
        ElectricityMode.fixed => 150000,
        ElectricityMode.items => 20000,
        ElectricityMode.itemsAndPower => 44000,
      });
      if (mode == ElectricityMode.itemsAndPower) {
        expect(result.kwh, 24);
        expect(result.energyFee, 24000);
      }
    }
  });

  test('Jumlah nol, beberapa barang, dan tarif desimal dihitung tanpa pembulatan awal', () {
    const pricing = ElectricityPricing(
      mode: ElectricityMode.itemsAndPower,
      pricePerKwh: 1444.7,
      items: [
        item,
        ElectricityItem(name: 'Laptop', watts: 65),
      ],
    );
    expect(pricing.estimate([]).total, 0);
    final result = pricing.estimate([
      const ElectricityUsage(quantity: 1, hoursPerDay: 2.5),
      const ElectricityUsage(quantity: 1, hoursPerDay: 4),
    ]);
    expect(result.kwh, closeTo(11.55, 0.00001));
    expect(result.total, (10000 + 11.55 * 1444.7).round());
  });

  test(
    'Data lama tetap bulanan; semua kategori bertahan setelah serialisasi',
    () {
      final legacy = KosModel.fromFirestore({
        'electrical_cost': {'listrik': 150000},
      }, 'old');
      expect(legacy.electricity.mode, ElectricityMode.fixed);
      expect(legacy.electricity.estimate([]).total, 150000);
      for (final mode in ElectricityMode.values) {
        final map = legacy.toFirestore();
        map['created_at'] = null;
        map['electricity_pricing'] = ElectricityPricing(
          mode: mode,
          pricePerKwh: 1444.7,
          items: [item],
          fixedMonthly: 50000,
        ).toMap();
        final decoded = KosModel.fromFirestore(map, 'new');
        expect(decoded.electricity.mode, mode);
        expect(decoded.electricity.pricePerKwh, 1444.7);
        expect(decoded.electricity.items.single.name, 'Kipas');
        expect(
          decoded.toFirestore()['electricity_pricing'],
          map['electricity_pricing'],
        );
      }
    },
  );

  testWidgets(
    'Pencari mengatur jumlah dan jam; total kos ikut berubah di layar kecil',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final kos = KosModel.fromFirestore({
        'rent_price': 1000000,
        'electricity_pricing': const ElectricityPricing(
          mode: ElectricityMode.itemsAndPower,
          pricePerKwh: 1000,
          unitMonthlyFee: 10000,
        ).toMap(),
      }, 'kos');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: KosCostCalculator(kost: kos)),
          ),
        ),
      );
      final add = find.byKey(const ValueKey('add_personal_item'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('item_0_name')),
        'Kipas pribadi',
      );
      await tester.enterText(find.byKey(const ValueKey('item_0_watts')), '50');
      final plus = find.byKey(const ValueKey('item_0_plus'));
      await tester.ensureVisible(plus);
      await tester.tap(plus);
      await tester.pump();
      expect(find.text('Total listrik / bulan: Rp 44.000'), findsOneWidget);
      expect(find.text('Rp 1.044.000'), findsNWidgets(2));
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('item_0_hours')),
      );
      slider.onChanged!(4);
      await tester.pump();
      expect(find.text('Total listrik / bulan: Rp 32.000'), findsOneWidget);
      expect(find.text('Rp 1.032.000'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Pencari menambah dan menghapus barang menggunakan tarif pemilik',
    (tester) async {
      final kos = KosModel.fromFirestore({
        'rent_price': 1000000,
        'electricity_pricing': const ElectricityPricing(
          mode: ElectricityMode.items,
          unitMonthlyFee: 25000,
        ).toMap(),
      }, 'kos-pribadi');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: KosCostCalculator(kost: kos)),
          ),
        ),
      );
      final add = find.byKey(const ValueKey('add_personal_item'));
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
      }
      expect(find.text('Total listrik / bulan: Rp 50.000'), findsOneWidget);
      expect(find.text('Daya per unit (watt)'), findsNothing);
      final remove = find.byKey(const ValueKey('item_0_delete'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('Total listrik / bulan: Rp 25.000'), findsOneWidget);
      expect(find.text('Rp 1.025.000'), findsNWidgets(2));
      final electricityToggle = find.byKey(const ValueKey('cost_listrik'));
      await tester.ensureVisible(electricityToggle);
      await tester.tap(electricityToggle);
      await tester.pumpAndSettle();
      expect(find.text('Rp 1.000.000'), findsNWidgets(3));
      await tester.tap(electricityToggle);
      await tester.pumpAndSettle();
      expect(find.text('Rp 1.025.000'), findsNWidgets(2));
      expect(kos.electricity.items, isEmpty);
      expect(kos.electricity.feePerUnit, 25000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Pemilik hanya menentukan tarif tanpa form barang', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    ElectricityPricing? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: form,
              child: ElectricityPricingEditor(
                initialValue: const ElectricityPricing(fixedMonthly: 50000),
                onChanged: (value) => result = value,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Biaya listrik tetap (Rp/bulan)'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<ElectricityMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ElectricityMode.itemsAndPower.label).last);
    await tester.pumpAndSettle();
    expect(find.text('Biaya listrik tetap (Rp/bulan)'), findsNothing);
    expect(find.text('Nama barang elektronik'), findsNothing);
    expect(find.text('Tambah barang elektronik'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tarif listrik (Rp/kWh)'),
      '1444,7',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Biaya barang (Rp/unit/bulan)'),
      '10000',
    );
    expect(find.text('Daya per unit (watt)'), findsNothing);
    expect(form.currentState!.validate(), isTrue);
    expect(result!.mode, ElectricityMode.itemsAndPower);
    expect(result!.pricePerKwh, 1444.7);
    expect(result!.feePerUnit, 10000);
    expect(result!.items, isEmpty);
    expect(ElectricityPricing.fromMap(result!.toMap()).feePerUnit, 10000);
    expect(tester.takeException(), isNull);
  });
}
