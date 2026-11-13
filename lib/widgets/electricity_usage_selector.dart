import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/electricity_pricing.dart';

class ElectricityUsageSelector extends StatefulWidget {
  final ElectricityPricing pricing;
  final ValueChanged<ElectricityEstimate> onChanged;

  const ElectricityUsageSelector({
    super.key,
    required this.pricing,
    required this.onChanged,
  });

  @override
  State<ElectricityUsageSelector> createState() =>
      _ElectricityUsageSelectorState();
}

class _PersonalItem {
  final key = UniqueKey();
  final name = TextEditingController();
  final watts = TextEditingController(text: '0');
  int quantity = 1;
  double hoursPerDay = 8;

  void dispose() {
    name.dispose();
    watts.dispose();
  }
}

class _ElectricityUsageSelectorState extends State<ElectricityUsageSelector> {
  final List<_PersonalItem> _items = [];

  double _watts(String text) {
    final value = double.tryParse(text.replaceAll(',', '.'));
    return value != null && value.isFinite && value >= 0 ? value : 0;
  }

  ElectricityEstimate get _estimate => widget.pricing.estimateCustom(
    _items
        .map(
          (item) => ElectricityItem(
            name: item.name.text.trim(),
            watts: _watts(item.watts.text),
          ),
        )
        .toList(),
    _items
        .map(
          (item) => ElectricityUsage(
            quantity: item.quantity,
            hoursPerDay: item.hoursPerDay,
          ),
        )
        .toList(),
  );

  void _changed() {
    setState(() {});
    widget.onChanged(_estimate);
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pricing = widget.pricing;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final estimate = _estimate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pricing.mode.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tambahkan barang elektronik yang akan Anda bawa. Daftar ini hanya untuk simulasi Anda.',
        ),
        Text(
          'Tarif pemilik: ${currency.format(pricing.feePerUnit)}/unit/bulan.',
        ),
        if (pricing.mode == ElectricityMode.itemsAndPower)
          Text(
            'Tarif daya: ${NumberFormat('#,##0.##', 'id_ID').format(pricing.pricePerKwh)} Rp/kWh. Estimasi 30 hari per bulan.',
          ),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada barang. Tambahkan barang untuk menghitung tagihan listrik.',
            ),
          ),
        for (var index = 0; index < _items.length; index++)
          Builder(
            builder: (context) {
              final item = _items[index];
              return Padding(
                key: item.key,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Barang ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('item_${index}_delete'),
                          tooltip: 'Hapus barang',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            _items.remove(item);
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => item.dispose(),
                            );
                            _changed();
                          },
                        ),
                      ],
                    ),
                    TextFormField(
                      key: ValueKey('item_${index}_name'),
                      controller: item.name,
                      decoration: const InputDecoration(
                        labelText: 'Nama barang elektronik',
                        hintText: 'Contoh: Kipas angin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (pricing.mode == ElectricityMode.itemsAndPower) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey('item_${index}_watts'),
                        controller: item.watts,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Daya per unit (watt)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (text) {
                          final value = double.tryParse(
                            (text ?? '').replaceAll(',', '.'),
                          );
                          return value == null || !value.isFinite || value < 0
                              ? 'Masukkan daya 0 atau lebih'
                              : null;
                        },
                        onChanged: (_) => _changed(),
                      ),
                    ],
                    Row(
                      children: [
                        const Expanded(child: Text('Jumlah unit')),
                        IconButton(
                          key: ValueKey('item_${index}_minus'),
                          tooltip: 'Kurangi jumlah unit',
                          onPressed: item.quantity == 0
                              ? null
                              : () {
                                  item.quantity--;
                                  _changed();
                                },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${item.quantity}',
                          key: ValueKey('item_${index}_quantity'),
                        ),
                        IconButton(
                          key: ValueKey('item_${index}_plus'),
                          tooltip: 'Tambah jumlah unit',
                          onPressed: item.quantity >= 99
                              ? null
                              : () {
                                  item.quantity++;
                                  _changed();
                                },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    if (pricing.mode == ElectricityMode.itemsAndPower &&
                        item.quantity > 0) ...[
                      Text(
                        'Pemakaian: ${item.hoursPerDay.toStringAsFixed(1)} jam/hari',
                      ),
                      Slider(
                        key: ValueKey('item_${index}_hours'),
                        value: item.hoursPerDay,
                        min: 0,
                        max: 24,
                        divisions: 48,
                        label: '${item.hoursPerDay} jam',
                        onChanged: (hours) {
                          item.hoursPerDay = hours;
                          _changed();
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        TextButton.icon(
          key: const ValueKey('add_personal_item'),
          icon: const Icon(Icons.add),
          label: const Text('Tambah barang elektronik'),
          onPressed: () {
            _items.add(_PersonalItem());
            _changed();
          },
        ),
        Text('Biaya barang / bulan: ${currency.format(estimate.itemFees)}'),
        if (pricing.mode == ElectricityMode.itemsAndPower) ...[
          Text(
            'Estimasi energi: ${NumberFormat('#,##0.##', 'id_ID').format(estimate.kwh)} kWh/bulan',
          ),
          Text('Biaya daya / bulan: ${currency.format(estimate.energyFee)}'),
          const Text(
            '(watt ÷ 1.000) × jumlah × jam/hari × 30 × tarif/kWh',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
        Text(
          'Total listrik / bulan: ${currency.format(estimate.total)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),
      ],
    );
  }
}
