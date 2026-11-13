import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/kos_model.dart';
import '../models/electricity_pricing.dart';
import 'electricity_usage_selector.dart';

/// Simulasi lokal; pilihan pencari tidak mengubah tarif milik pemilik kos.
class KosCostCalculator extends StatefulWidget {
  final KosModel kost;

  const KosCostCalculator({super.key, required this.kost});

  @override
  State<KosCostCalculator> createState() => _KosCostCalculatorState();
}

class _KosCostCalculatorState extends State<KosCostCalculator> {
  int _months = 1;
  ElectricityEstimate? _personalElectricity;
  final Set<String> _included = {'air', 'listrik', 'wifi'};
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void didUpdateWidget(covariant KosCostCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kost.id != widget.kost.id) {
      _months = 1;
      _personalElectricity = null;
      _included.addAll({'air', 'listrik', 'wifi'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricing = widget.kost.electricity;
    final electricity = pricing.mode == ElectricityMode.fixed
        ? pricing.estimate([])
        : _personalElectricity ?? const ElectricityEstimate(total: 0);
    final costs = <String, int>{
      'air': widget.kost.reccuringCost['air'] ?? 0,
      'listrik': electricity.total,
      'wifi': widget.kost.reccuringCost['wifi'] ?? 0,
    };
    const labels = {'air': 'Air', 'listrik': 'Listrik', 'wifi': 'Wi-Fi'};
    final additional = costs.entries
        .where((entry) => _included.contains(entry.key))
        .fold<int>(0, (sum, entry) => sum + entry.value);
    final monthly = widget.kost.rentPrice + additional;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate_outlined, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kalkulator Biaya Kos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tarif per bulan dari pemilik. Pilih biaya tambahan untuk simulasi anggaran Anda.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _costRow('Sewa kos / bulan', widget.kost.rentPrice),
            const SizedBox(height: 8),
            for (final entry in costs.entries)
              CheckboxListTile(
                key: ValueKey('cost_${entry.key}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(labels[entry.key]!),
                subtitle: Text(
                  entry.key == 'listrik' &&
                          pricing.mode != ElectricityMode.fixed
                      ? pricing.mode.label
                      : entry.value == 0
                      ? 'Tidak ada biaya tambahan'
                      : '${_currency.format(entry.value)} / bulan',
                ),
                value: _included.contains(entry.key),
                onChanged:
                    entry.value == 0 &&
                        !(entry.key == 'listrik' &&
                            pricing.mode != ElectricityMode.fixed)
                    ? null
                    : (selected) => setState(() {
                        if (selected == true) {
                          _included.add(entry.key);
                        } else {
                          _included.remove(entry.key);
                        }
                      }),
              ),
            if (pricing.mode != ElectricityMode.fixed)
              Offstage(
                offstage: !_included.contains('listrik'),
                child: ElectricityUsageSelector(
                  key: ValueKey(widget.kost.id),
                  pricing: pricing,
                  onChanged: (estimate) =>
                      setState(() => _personalElectricity = estimate),
                ),
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _months,
              decoration: const InputDecoration(
                labelText: 'Lama sewa',
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (index) => index + 1)
                  .map(
                    (months) => DropdownMenuItem(
                      value: months,
                      child: Text('$months bulan'),
                    ),
                  )
                  .toList(),
              onChanged: (months) {
                if (months != null) setState(() => _months = months);
              },
            ),
            const SizedBox(height: 16),
            _costRow('Biaya tambahan / bulan', additional),
            const SizedBox(height: 8),
            _costRow('Total / bulan', monthly),
            const Divider(height: 24),
            _costRow(
              'Total $_months bulan',
              monthly * _months,
              emphasized: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Estimasi sesuai pilihan di atas. Konfirmasikan biaya wajib dan tagihan berdasarkan pemakaian kepada pemilik.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _costRow(String label, int amount, {bool emphasized = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            _currency.format(amount),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: emphasized ? AppTheme.primaryBlue : Colors.black87,
              fontSize: emphasized ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
