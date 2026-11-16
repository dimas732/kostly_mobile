import 'package:flutter/material.dart';

class ElectronicItem {
  final String id;
  final String name;
  final IconData icon;
  final int defaultWatt;
  final int defaultHoursPerDay;
  int quantity;
  bool isSelected;
  final bool isCustom; // 🔹 Penanda apakah ini barang kustom buatan pengguna

  ElectronicItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.defaultWatt,
    required this.defaultHoursPerDay,
    this.quantity = 1,
    this.isSelected = false,
    this.isCustom = false, // Default false untuk preset bawaan
  });
}

// Daftar Katalog Preset Perangkat Elektronik Umum di Kos
List<ElectronicItem> getPredefinedElectronics() {
  return [
    ElectronicItem(
      id: 'laptop',
      name: 'Laptop / PC',
      icon: Icons.laptop_mac_rounded,
      defaultWatt: 65,
      defaultHoursPerDay: 6,
    ),
    ElectronicItem(
      id: 'rice_cooker',
      name: 'Magic Com / Rice Cooker',
      icon: Icons.rice_bowl_rounded,
      defaultWatt: 350,
      defaultHoursPerDay: 2,
    ),
    ElectronicItem(
      id: 'kulkas_mini',
      name: 'Kulkas Mini',
      icon: Icons.kitchen_rounded,
      defaultWatt: 80,
      defaultHoursPerDay: 24, // Menyala 24 jam penuh
    ),
    ElectronicItem(
      id: 'kipas_angin',
      name: 'Kipas Angin',
      icon: Icons.air_rounded,
      defaultWatt: 45,
      defaultHoursPerDay: 8,
    ),
    ElectronicItem(
      id: 'setrika',
      name: 'Setrika Baju',
      icon: Icons.iron_rounded,
      defaultWatt: 300,
      defaultHoursPerDay: 1,
    ),
    ElectronicItem(
      id: 'dispenser',
      name: 'Dispenser',
      icon: Icons.local_drink_rounded,
      defaultWatt: 200,
      defaultHoursPerDay: 5,
    ),
    ElectronicItem(
      id: 'charger_hp',
      name: 'Smartphone / Tablet',
      icon: Icons.phone_android_rounded,
      defaultWatt: 15,
      defaultHoursPerDay: 3,
    ),
  ];
}