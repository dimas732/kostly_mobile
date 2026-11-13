import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/electricity_pricing.dart';

class ElectricityPricingEditor extends StatefulWidget {
  final ElectricityPricing initialValue;
  final ValueChanged<ElectricityPricing> onChanged;

  const ElectricityPricingEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<ElectricityPricingEditor> createState() =>
      _ElectricityPricingEditorState();
}

class _ElectricityPricingEditorState extends State<ElectricityPricingEditor> {
  late ElectricityMode _mode;
  late TextEditingController _fixed;
  late TextEditingController _tariff;
  late TextEditingController _unitFee;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialValue.mode;
    _fixed = TextEditingController(
      text: widget.initialValue.fixedMonthly.toString(),
    );
    _tariff = TextEditingController(
      text: widget.initialValue.pricePerKwh.toString(),
    );
    _unitFee = TextEditingController(
      text: widget.initialValue.feePerUnit.toString(),
    );
  }

  void _notify() => widget.onChanged(
    ElectricityPricing(
      mode: _mode,
      fixedMonthly: int.tryParse(_fixed.text) ?? 0,
      pricePerKwh: double.tryParse(_tariff.text.replaceAll(',', '.')) ?? 0,
      unitMonthlyFee: int.tryParse(_unitFee.text) ?? 0,
    ),
  );

  @override
  void dispose() {
    _fixed.dispose();
    _tariff.dispose();
    _unitFee.dispose();
    super.dispose();
  }

  Widget _number(
    TextEditingController controller,
    String label, {
    bool decimal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
          ),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _notify(),
        validator: (value) {
          final number = decimal
              ? double.tryParse((value ?? '').replaceAll(',', '.'))
              : int.tryParse(value ?? '');
          return number == null || !number.isFinite || number < 0
              ? 'Masukkan angka 0 atau lebih'
              : null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perhitungan Biaya Listrik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ElectricityMode>(
          initialValue: _mode,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Kategori biaya listrik',
            border: OutlineInputBorder(),
          ),
          items: ElectricityMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (mode) {
            if (mode == null) return;
            setState(() => _mode = mode);
            _notify();
          },
        ),
        if (_mode == ElectricityMode.fixed)
          _number(_fixed, 'Biaya listrik tetap (Rp/bulan)')
        else ...[
          const SizedBox(height: 12),
          Text(
            _mode == ElectricityMode.items
                ? 'Tentukan biaya per unit barang per bulan. Pencari memilih jumlah barang yang dibawa.'
                : 'Biaya per unit barang ditambah pemakaian daya. Estimasi memakai 30 hari per bulan.',
          ),
          if (_mode == ElectricityMode.itemsAndPower)
            _number(_tariff, 'Tarif listrik (Rp/kWh)', decimal: true),
          _number(_unitFee, 'Biaya barang (Rp/unit/bulan)'),
          const SizedBox(height: 8),
          const Text(
            'Pencari menambahkan sendiri nama barang dan jumlah unit di detail kos. Untuk kategori barang + daya, pencari juga mengisi watt dan jam pemakaian.',
          ),
        ],
      ],
    );
  }
}
