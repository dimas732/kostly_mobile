import 'package:flutter/material.dart';
import '../models/calculator_model.dart';
import '../services/electricity_calculator.dart';
import '../core/app_theme.dart';

class ElectricityCalculatorScreen extends StatefulWidget {
  const ElectricityCalculatorScreen({super.key});

  @override
  State<ElectricityCalculatorScreen> createState() => _ElectricityCalculatorScreenState();
}

class _ElectricityCalculatorScreenState extends State<ElectricityCalculatorScreen> {
  late List<ElectronicItem> _items;

  @override
  void initState() {
    super.initState();
    _items = getPredefinedElectronics();
  }

  // 🔹 Fungsi untuk memunculkan Dialog Tambah Perangkat Kustom
  void _showAddCustomItemDialog() {
    final nameController = TextEditingController();
    final wattController = TextEditingController();
    final hoursController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tambah Perangkat Lain',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang (Contoh: Hair Dryer)',
                hintText: 'Masukkan nama perangkat',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: wattController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daya (Watt)',
                hintText: 'Contoh: 350',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durasi Pemakaian (Jam / Hari)',
                hintText: 'Contoh: 1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && wattController.text.isNotEmpty) {
                final int watt = int.tryParse(wattController.text) ?? 50;
                final int hours = int.tryParse(hoursController.text) ?? 1;

                setState(() {
                  _items.add(
                    ElectronicItem(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      icon: Icons.devices_other_rounded,
                      defaultWatt: watt,
                      defaultHoursPerDay: hours,
                      quantity: 1,
                      isSelected: true, // Otomatis dicentang saat ditambahkan
                      isCustom: true,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hitung hasil kalkulasi secara real-time
    final calculationResult = ElectricityCalculator.calculateTotal(_items);
    final double totalCost = calculationResult['totalCost'];
    final double totalKwh = calculationResult['totalKwh'];
    final int totalWatt = calculationResult['totalWatt'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Kalkulator Biaya Listrik',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // 1. KARTU RINGKASAN HASIL ESTIMASI DI BAGIAN ATAS
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Estimasi Tambahan Biaya Listrik / Bulan',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${_formatRupiah(totalCost)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Daya', '$totalWatt Watt'),
                    Container(height: 25, width: 1, color: Colors.white30),
                    _buildSummaryItem('Konsumsi', '${totalKwh.toStringAsFixed(1)} kWh'),
                  ],
                ),
              ],
            ),
          ),

          // 2. HEADER & TOMBOL TAMBAH KUSTOM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Perangkat Elektronik:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
                TextButton.icon(
                  onPressed: _showAddCustomItemDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Lainnya'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 3. LIST PERANGKAT (CHECKLIST)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
                      width: item.isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    activeColor: AppTheme.primaryBlue,
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '~ ${item.defaultWatt} Watt (${item.defaultHoursPerDay} jam/hari)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: AppTheme.primaryBlue, size: 22),
                    ),
                    value: item.isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        item.isSelected = value ?? false;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  String _formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}