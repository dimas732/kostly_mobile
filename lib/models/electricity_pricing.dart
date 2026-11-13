enum ElectricityMode {
  fixed('Biaya tetap per bulan'),
  items('Biaya berdasarkan barang elektronik'),
  itemsAndPower('Biaya barang + biaya daya listrik');

  final String label;
  const ElectricityMode(this.label);
}

class ElectricityItem {
  final String name;
  final int monthlyFee;
  final double watts;

  const ElectricityItem({
    required this.name,
    this.monthlyFee = 0,
    this.watts = 0,
  });

  factory ElectricityItem.fromMap(Map<String, dynamic> map) => ElectricityItem(
    name: map['name']?.toString() ?? '',
    monthlyFee: (map['monthly_fee'] as num?)?.toInt() ?? 0,
    watts: (map['watts'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'monthly_fee': monthlyFee,
    'watts': watts,
  };
}

class ElectricityUsage {
  final int quantity;
  final double hoursPerDay;

  const ElectricityUsage({this.quantity = 0, this.hoursPerDay = 8});
}

class ElectricityEstimate {
  final double itemFees;
  final double kwh;
  final double energyFee;
  final int total;

  const ElectricityEstimate({
    this.itemFees = 0,
    this.kwh = 0,
    this.energyFee = 0,
    required this.total,
  });
}

class ElectricityPricing {
  final ElectricityMode mode;
  final int fixedMonthly;
  final double pricePerKwh;
  final List<ElectricityItem> items;
  final int? unitMonthlyFee;

  int get feePerUnit =>
      unitMonthlyFee ?? (items.isEmpty ? 0 : items.first.monthlyFee);

  const ElectricityPricing({
    this.mode = ElectricityMode.fixed,
    this.fixedMonthly = 0,
    this.pricePerKwh = 0,
    this.items = const [],
    this.unitMonthlyFee,
  });

  factory ElectricityPricing.fromMap(Map<String, dynamic> map) =>
      ElectricityPricing(
        mode: ElectricityMode.values.firstWhere(
          (mode) => mode.name == map['mode'],
          orElse: () => ElectricityMode.fixed,
        ),
        fixedMonthly: (map['fixed_monthly'] as num?)?.toInt() ?? 0,
        pricePerKwh: (map['price_per_kwh'] as num?)?.toDouble() ?? 0,
        unitMonthlyFee: (map['unit_monthly_fee'] as num?)?.toInt(),
        items: (map['items'] as List? ?? [])
            .whereType<Map>()
            .map(
              (item) =>
                  ElectricityItem.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList(),
      );

  Map<String, dynamic> toMap() => {
    'mode': mode.name,
    'fixed_monthly': fixedMonthly,
    'price_per_kwh': pricePerKwh,
    'items': items.map((item) => item.toMap()).toList(),
    if (unitMonthlyFee != null) 'unit_monthly_fee': unitMonthlyFee,
  };

  ElectricityEstimate estimateCustom(
    List<ElectricityItem> selectedItems,
    List<ElectricityUsage> usage,
  ) => ElectricityPricing(
    mode: mode,
    fixedMonthly: fixedMonthly,
    pricePerKwh: pricePerKwh,
    items: selectedItems
        .map(
          (item) => ElectricityItem(
            name: item.name,
            watts: item.watts,
            monthlyFee: feePerUnit,
          ),
        )
        .toList(),
  ).estimate(usage);

  ElectricityEstimate estimate(List<ElectricityUsage> usage) {
    if (mode == ElectricityMode.fixed) {
      return ElectricityEstimate(total: fixedMonthly);
    }
    double fees = 0;
    double kwh = 0;
    for (var index = 0; index < items.length; index++) {
      final selected = index < usage.length
          ? usage[index]
          : const ElectricityUsage();
      final quantity = selected.quantity.clamp(0, 99);
      fees += items[index].monthlyFee * quantity;
      if (mode == ElectricityMode.itemsAndPower) {
        kwh +=
            items[index].watts /
            1000 *
            quantity *
            selected.hoursPerDay.clamp(0, 24) *
            30;
      }
    }
    final energy = kwh * pricePerKwh;
    return ElectricityEstimate(
      itemFees: fees,
      kwh: kwh,
      energyFee: energy,
      total: (fees + energy).round(),
    );
  }
}
